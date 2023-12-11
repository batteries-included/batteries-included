import os

import pytest
from hydra.core.hydra_config import HydraConfig
from omegaconf import open_dict

from src.train import train


def test_train_fast_dev_run(cfg_train):
    """Run for 1 train, val and test step."""
    HydraConfig().set_config(cfg_train)
    with open_dict(cfg_train):
        cfg_train.trainer.fast_dev_run = True
        cfg_train.trainer.accelerator = "cpu"
    train(cfg_train)
