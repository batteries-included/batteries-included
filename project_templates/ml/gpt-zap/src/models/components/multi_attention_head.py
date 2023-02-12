import torch
import torch.nn as nn

from .head import Head


class MultiHeadAttention(nn.Module):
    """multiple heads of self-attention in parallel"""

    def __init__(
        self,
        dim_model: int,
        num_heads: int,
        head_dropout: float,
        multi_head_dropout: float,
        *args,
        **kwargs
    ):
        super().__init__()
        self.heads = nn.ModuleList(
            [
                Head(dim_model, dim_model // num_heads, head_dropout)
                for _ in range(num_heads)
            ]
        )
        self.proj = nn.Linear(dim_model, dim_model)
        self.dropout = nn.Dropout(multi_head_dropout)

    def forward(self, x):
        out = torch.cat([h(x) for h in self.heads], dim=-1)
        out = self.proj(out)
        out = self.dropout(self.proj(out))
        return out
