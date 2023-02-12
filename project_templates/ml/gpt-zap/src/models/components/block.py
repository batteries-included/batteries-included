from xformers.components.feedforward import MLP

import torch.nn as nn

from .multi_attention_head import MultiHeadAttention


class Block(nn.Module):
    """Transformer block:

    Multi Head Attention
    Feed Forward
    """

    def __init__(
        self,
        dim_model,
        num_heads,
        head_dropout,
        multi_head_dropout,
        feed_forward_activation,
        feed_forward_dropout,
        feed_forward_layer_multiplier,
        *args,
        **kwargs
    ):
        super().__init__()

        self.multi_head = MultiHeadAttention(
            dim_model, num_heads, head_dropout, multi_head_dropout
        )
        self.feed_forward = MLP(
            dim_model,
            feed_forward_dropout,
            feed_forward_activation,
            feed_forward_layer_multiplier,
        )

        self.layer_norm_1 = nn.LayerNorm(dim_model)
        self.layer_norm_2 = nn.LayerNorm(dim_model)

    def forward(self, x):
        x = x + self.multi_head(self.layer_norm_1(x))
        x = x + self.feed_forward(self.layer_norm_2(x))
        return x
