from abc import ABC
from typing import Any

from pytorch_lightning import LightningModule
from torchmetrics import MeanMetric
from torch.nn import functional as F
from xformers.components.multi_head_dispatch import MultiHeadDispatch
from xformers.components.attention import ScaledDotProduct
from xformers.components.feedforward import MLP

import torch
import torch.nn as nn

from .components.block import Block
from .components.vocab_embedding import VocabEmbedding


class TinyGPT(ABC, LightningModule):
    def __init__(
        self, net: torch.nn.Module, optimizer: torch.optim.Optimizer, *args, **kwargs
    ):
        super().__init__()
        # this line allows to access init params with 'self.hparams' attribute
        # also ensures init params will be stored in ckpt
        self.save_hyperparameters(logger=False)
        # The everything
        self.net = net

        # loss function
        self.criterion = torch.nn.CrossEntropyLoss()
        # for averaging loss across batches
        self.train_loss = MeanMetric()
        self.val_loss = MeanMetric()
        self.test_loss = MeanMetric()

    def forward(self, idx: torch.Tensor):
        B, T = idx.shape
        x = self.net.forward(idx)
        B, T, C = x.shape
        logits = x.view(B * T, C)

        return logits

    def model_step(self, batch: Any):
        x, y = batch
        logits = self.forward(x)
        loss = self.criterion(logits, y.view(-1))
        preds = torch.argmax(logits, dim=1)
        return loss, preds, y

    def training_step(self, batch: Any, batch_idx: int):
        loss, preds, targets = self.model_step(batch)
        # update and log metrics
        self.train_loss(loss)
        self.log(
            "train/loss", self.train_loss, on_step=False, on_epoch=True, prog_bar=True
        )

        # we can return here dict with any tensors
        # and then read it in some callback or in `training_epoch_end()` below
        # remember to always return loss from `training_step()` or backpropagation will fail!
        return {"loss": loss, "preds": preds, "targets": targets}

    def validation_step(self, batch: Any, _batch_idx: int):
        loss, preds, targets = self.model_step(batch)
        # update and log metrics
        self.val_loss(loss)
        self.log("val/loss", self.val_loss, on_step=False, on_epoch=True, prog_bar=True)
        return {"loss": loss, "preds": preds, "targets": targets}

    def test_step(self, batch: Any, _batch_idx: int):
        loss, preds, targets = self.model_step(batch)

        # update and log metrics
        self.test_loss(loss)
        self.log(
            "test/loss", self.test_loss, on_step=False, on_epoch=True, prog_bar=True
        )
        return {"loss": loss, "preds": preds, "targets": targets}

    def configure_optimizers(self):
        # Create the optimizer and the training schedule:
        # - Handle the per-param weight decay
        no_decay = ["bias", "LayerNorm.weight"]
        params_decay = [
            p for n, p in self.named_parameters() if not any(nd in n for nd in no_decay)
        ]
        params_nodecay = [
            p for n, p in self.named_parameters() if any(nd in n for nd in no_decay)
        ]
        optim_groups = [
            {"params": params_decay, "weight_decay": 0.1},
            {"params": params_nodecay, "weight_decay": 0.0},
        ]

        optimizer = self.hparams.optimizer(optim_groups)  # type: ignore

        return {"optimizer": optimizer}

    def generate(self, idx, max_new_tokens):
        # idx is (B, T) array of indices in the current context
        for _ in range(max_new_tokens):
            # get the predictions
            logits = self.forward(idx)
            # focus only on the last time step
            logits = logits[:, -1, :]  # becomes (B, C)
            # apply softmax to get probabilities
            probs = F.softmax(logits, dim=-1)  # (B, C)
            # sample from the distribution
            idx_next = torch.multinomial(probs, num_samples=1)  # (B, 1)
            # append sampled index to the running sequence
            idx = torch.cat((idx, idx_next), dim=1)  # (B, T+1)
        return idx
