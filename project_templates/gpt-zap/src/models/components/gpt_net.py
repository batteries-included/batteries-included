import torch.nn as nn

from torch.nn import functional as F
from .block import Block
from .vocab_embedding import VocabEmbedding


class GPTNet(nn.Module):
    """The whole net"""

    def __init__(
        self,
        dim_model,
        num_heads,
        num_layers,
        embedding_dropout,
        head_dropout,
        multi_head_dropout,
        feed_forward_activation,
        feed_forward_layer_multiplier,
        feed_forward_dropout,
        sequence_length,
        vocab_size,
        *args,
        **kwargs
    ):
        super().__init__()
        self.model = nn.Sequential()
        self.model.append(
            VocabEmbedding(dim_model, sequence_length, vocab_size, embedding_dropout)
        )

        for _ in range(num_layers):
            self.model.append(
                Block(
                    dim_model,
                    num_heads,
                    head_dropout,
                    multi_head_dropout,
                    feed_forward_activation,
                    feed_forward_dropout,
                    feed_forward_layer_multiplier,
                )
            )

        self.model.append(nn.LayerNorm(dim_model, dim_model))
        self.model.append(nn.Linear(dim_model, vocab_size))
        # Store the sequence_length so we can ignore longer input
        # sequences for example during generation
        self.sequence_length = sequence_length

    def forward(self, x):
        B, T = x.shape
        if T > self.sequence_length:
            x = x[:, -self.sequence_length]
        return self.model(x)
