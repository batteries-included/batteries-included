from abc import ABC
from pytorch_lightning import LightningDataModule
from src import utils
from torch.utils.data import Dataset, DataLoader, random_split, SubsetRandomSampler
from torchtext.utils import download_from_url
from typing import Any, Optional, Tuple

import tiktoken
import os
import torch


log = utils.get_pylogger(__name__)


class TinyShakespeare(Dataset):
    URL = "https://raw.githubusercontent.com/karpathy/char-rnn/master/data/tinyshakespeare/input.txt"

    def __init__(
        self, data_dir: str = "data/", sequence_length: int = 128, encoder_type="char"
    ) -> None:
        super().__init__()
        self.data_dir = data_dir
        self.sequence_length = sequence_length
        self.encoder_type = encoder_type
        self.encoder_fun: Optional[Any] = None
        self.dencoder_fun: Optional[Any] = None
        self.vocab_size = 50304
        os.makedirs(data_dir, exist_ok=True)
        self.text_file_path = self.download(data_dir)

        with open(self.text_file_path) as f:
            self.data = self.read(f)
        self.data = self.encode(self.data)
        self.data = self.to_tensor(self.data)

    def __getitem__(self, index):
        # The first is the context in
        # The second is the target. Target is the sequence shifted over one.

        return (
            self.data[index : index + self.sequence_length],
            self.data[index + 1 : index + self.sequence_length + 1],
        )

    def __len__(self):
        return len(self.data) - self.sequence_length

    def download(self, data_folder) -> str:
        return download_from_url(
            self.URL, path=os.path.join(data_folder, "tiny_shakespeare-data.txt")
        )

    def read(self, f):
        self.data = f.read()
        return self.data

    def encode(self, data):
        if self.encoder_type == "gpt2":
            enc = tiktoken.get_encoding("gpt2")
            self.data = enc.encode_ordinary(data)
        elif self.encoder_type == "char":
            self.vocab_size = 128
            self.encode_fun = lambda s: [
                ord(c) for c in s
            ]  # encoder: take a string, output a list of integers
            self.decode_fun = lambda l: "".join(
                [chr(i) for i in l]
            )  # decoder: take a list of integers, output a string
            self.data = self.encode_fun(data)
        return self.data

    def to_tensor(self, data):
        self.data = torch.tensor(data, dtype=torch.long)
        return self.data


class TinyShakespeareDataModule(ABC, LightningDataModule):
    def __init__(
        self,
        data_dir: str = "data/",
        train_val_test_split: Tuple[float, float, float] = (0.90, 0.05, 0.05),
        encoder_type: str = "gpt2",
        sequence_length: int = 8,
        batch_size: int = 64,
        num_workers: int = 0,
        pin_memory: bool = False,
    ):
        super().__init__()
        self.save_hyperparameters(logger=False)
        self.full: Optional[Dataset] = None
        self.data_train: Optional[Dataset] = None
        self.data_val: Optional[Dataset] = None
        self.data_test: Optional[Dataset] = None

    def prepare_data(self) -> None:
        self.full = TinyShakespeare(
            self.hparams.data_dir,
            self.hparams.sequence_length,
            self.hparams.encoder_type,
        )

    def setup(self, stage: Optional[str] = None) -> None:
        self.data_train, self.data_val, self.data_test = random_split(
            dataset=self.full,
            lengths=self.hparams.train_val_test_split,
        )

    def train_dataloader(self):
        return DataLoader(
            dataset=self.data_train,
            shuffle=True,
            batch_size=self.hparams.batch_size,
            num_workers=self.hparams.num_workers,
            pin_memory=self.hparams.pin_memory,
        )

    def val_dataloader(self):
        return DataLoader(
            dataset=self.data_val,
            shuffle=False,
            batch_size=self.hparams.batch_size,
            num_workers=self.hparams.num_workers,
            pin_memory=self.hparams.pin_memory,
        )

    def test_dataloader(self):
        return DataLoader(
            dataset=self.data_test,
            shuffle=False,
            batch_size=self.hparams.batch_size,
            num_workers=self.hparams.num_workers,
            pin_memory=self.hparams.pin_memory,
        )
