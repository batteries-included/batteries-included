#!/usr/bin/env python

from setuptools import find_packages, setup

setup(
    name="src",
    version="0.0.1",
    description="GPT Zap powered with Lightning",
    author="Elliott Clark",
    author_email="elliott@batteriesincl.com",
    url="https://github.com/batteriesincl/main",
    install_requires=["pytorch-lightning", "hydra-core"],
    packages=find_packages(),
)
