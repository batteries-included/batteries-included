from pathlib import Path

import pytest
import torch

from src.data.tiny_shakespeare_datamodule import TinyShakespeareDataModule


@pytest.mark.parametrize("batch_size", [32, 128])
def test_tiny_shakespeare_datamodule(batch_size):
    data_dir = "data/"

    dm = TinyShakespeareDataModule(data_dir=data_dir, batch_size=batch_size)
    dm.prepare_data()

    assert not dm.data_train and not dm.data_val and not dm.data_test
    assert Path(data_dir, "input.txt").exists()

    dm.setup()
    assert dm.data_train and dm.data_val and dm.data_test
    assert dm.train_dataloader() and dm.val_dataloader() and dm.test_dataloader()

    # num_datapoints = len(dm.data_train) + len(dm.data_val) + len(dm.data_test)
    # assert num_datapoints >= 300_000

    batch = next(iter(dm.train_dataloader()))
    x, y = batch
    assert len(x) == batch_size
    assert len(y) == batch_size
