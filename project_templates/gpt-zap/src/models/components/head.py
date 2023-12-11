from typing import Optional
import torch
import torch.nn as nn

from torch.nn import functional as F
from .rotary import RotaryEmbedding


class Head(nn.Module):
    """
    Single HEAD module of attention.

    Project the input into a key and a query. (Both are the same currently)
    Add a rotational embeddin
    use bottom triangle and softmax to mask attention.
    """

    tril: Optional[torch.Tensor]

    def __init__(
        self, dim_model: int, head_size: int, attention_dropout: float, *args, **kwargs
    ):
        super().__init__()
        self.key = nn.Linear(dim_model, head_size, bias=False)
        self.query = nn.Linear(dim_model, head_size, bias=False)
        self.rotary_embedding = RotaryEmbedding(head_size)
        self.value = nn.Linear(dim_model, head_size, bias=False)

        self.dropout = nn.Dropout(attention_dropout)
        self.tril: Optional[torch.Tensor] = None

    def forward(self, x):
        B, T, C = x.shape

        # Store the bottom half ones
        if self.tril is None:
            self.tril = torch.tril(torch.ones(T, T, device=x.device))

        q = self.query(x)  # (B,T,C)
        k = self.key(x)  # (B,T,C)

        # Add on rotary embedding
        # This is a transform that rotates query and key
        # dependent on their relative positions,
        # effectively adding in some information
        # about sequence length position (both relative and absolute)
        q_prime, k_prime = self.rotary_embedding.forward(q, k)

        # compute attention scores ("affinities")
        wei = (
            q_prime @ k_prime.transpose(-2, -1) * C**-0.5
        )  # (B, T, C) @ (B, C, T) -> (B, T, T)
        wei = wei.masked_fill(self.tril[:T, :T] == 0, float("-inf"))  # (B, T, T)
        wei = F.softmax(wei, dim=-1)  # (B, T, T)
        wei = self.dropout(wei)

        # Now project the sequences into different
        # output values ignoring causality and attention
        v = self.value(x)  # (B,T,C)

        # perform the weighted aggregation of the values with respect causality
        out = wei @ v  # (B, T, T) @ (B, T, C) -> (B, T, C)
        return out
