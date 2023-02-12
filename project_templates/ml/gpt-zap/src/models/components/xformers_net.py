import torch.nn as nn

from xformers.factory.model_factory import xFormer, xFormerConfig
from xformers.factory.weight_init import xFormerWeightInit


class XFormersNet(nn.Module):
    """The whole net"""

    def __init__(
        self,
        dim_model,
        num_heads,
        num_layers,
        residual_dropout,
        attention_dropout,
        feed_forward_dropout,
        feed_forward_activation,
        feed_forward_layer_multiplier,
        sequence_length,
        vocab_size,
    ):
        super().__init__()

        # A list of the encoder or decoder blocks which constitute the Transformer.
        xformer_config = [
            {
                "reversible": False,  # Turn on to test the effect of using reversible layers
                "block_type": "encoder",
                "num_layers": num_layers,
                "dim_model": dim_model,
                "residual_norm_style": "post",
                "position_encoding_config": {
                    "name": "vocab",
                    "seq_len": sequence_length,
                    "vocab_size": vocab_size,
                },
                "multi_head_config": {
                    "num_heads": num_heads,
                    "residual_dropout": residual_dropout,
                    "use_rotary_embeddings": True,
                    "attention": {
                        "name": "scaled_dot_product",
                        "dropout": attention_dropout,
                        "causal": True,
                        "seq_len": sequence_length,
                        "num_rules": num_heads,
                    },
                },
                "feedforward_config": {
                    "name": "MLP",
                    "dropout": feed_forward_dropout,
                    "activation": feed_forward_activation,
                    "hidden_layer_multiplier": feed_forward_layer_multiplier,
                },
            }
        ]

        config = xFormerConfig(xformer_config)
        config.weight_init = xFormerWeightInit.Small
        model = xFormer.from_config(config)
        ln_f = nn.LayerNorm(dim_model)
        head = nn.Linear(dim_model, vocab_size, bias=False)
        self.model = nn.Sequential(model, ln_f, head)

    def forward(self, x):
        return self.model(x)
