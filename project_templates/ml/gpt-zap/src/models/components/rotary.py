import torch


def rotate_half(x):
    x1, x2 = x.chunk(2, dim=-1)
    return torch.cat((-x2, x1), dim=-1)


@torch.jit.script
def apply_rotary_pos_emb(x, cos, sin):
    cos = cos[:, :, : x.shape[-2], :]
    sin = sin[:, :, : x.shape[-2], :]

    return (x * cos) + (rotate_half(x) * sin)


class RotaryEmbedding(torch.nn.Module):
    def __init__(self, dim, base=10000):
        super().__init__()
        inv_freq = 1.0 / (base ** (torch.arange(0, dim, 2).float() / dim))
        self.register_buffer("inv_freq", inv_freq)
        self.seq_len_cached = None
        self.cos_cached = None
        self.sin_cached = None

    def forward(self, q, k, seq_dim=1):
        seq_len = q.shape[seq_dim]
        if seq_len != self.seq_len_cached:
            self.seq_len_cached = seq_len
            t = torch.arange(seq_len, device=q.device, dtype=torch.float32)
            freqs = torch.einsum("i,j->ij", t, self.inv_freq.to(q.dtype))
            emb = torch.cat((freqs, freqs), dim=-1).to(q.device)
            self.cos_cached = emb.cos()[None, None, :, :].to(q.dtype)
            self.sin_cached = emb.sin()[None, None, :, :].to(q.dtype)

        return (
            apply_rotary_pos_emb(q, self.cos_cached, self.sin_cached).flatten(0, 1),
            apply_rotary_pos_emb(k, self.cos_cached, self.sin_cached).flatten(0, 1),
        )
