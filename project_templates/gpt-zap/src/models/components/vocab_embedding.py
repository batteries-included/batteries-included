from typing import Optional
from torch.nn import functional as F

import torch
import torch.nn as nn


class VocabEmbedding(nn.Module):
    position_ids: Optional[torch.Tensor]

    def __init__(
        self,
        dim_model: int,
        sequence_length: int,
        vocab_size: int,
        embedding_dropout: float = 0.0,
        *args,
        **kwargs
    ):
        super().__init__()

        self.vocab_size = vocab_size
        self.dim_model = dim_model

        self.position_embeddings = nn.Embedding(sequence_length, self.dim_model)
        self.token_embedding = nn.Embedding(self.vocab_size, self.dim_model)
        self.dropout = torch.nn.Dropout(p=embedding_dropout)
        self.position_ids = None

    def forward(self, x: torch.Tensor):
        if self.position_ids is None:
            # Create a tensor of the token positions.
            # Use this as indecies into the position encoding table.
            self.position_ids = torch.arange(
                x.shape[1], dtype=torch.long, device=x.device
            )

        x = self.token_embedding(x) + self.position_embeddings(self.position_ids)
        x = self.dropout(x)
        return x
