---
title: "Larger LLMs aren't all you need"
tags: ['AI', 'LLM', 'NLP']
date: 2023-09-20
draft: true
---

Lately, GPTs and LLMs have been all the rage. Their groundbreaking successes are
numerous and cause for celebration. However, as the models have scaled and
results have improved, it's easy to slip into hoping or wishing that larger and
larger transformer models will solve everything. In this blog post, we'll
explore what LLMs and GPTs are, why there's reason to be cautious around the
panacea of ChatGPT saving the world, and then guess a little about what that
means as we move through the trough of disillusionment to the slope of
enlightenment.

# The Rise of Large Language Models

In the realm of artificial intelligence, large language models (LLMs) like
[GPT-3](https://arxiv.org/abs/2005.14165),
[GPT-4](https://openai.com/research/gpt-4),
[PaLM](https://arxiv.org/abs/2204.02311),
[LLaMa](https://arxiv.org/abs/2108.06084),
[LLaMa 2](https://arxiv.org/abs/2307.09288), and
[BERT](https://arxiv.org/abs/1810.04805) have revolutionized text generation and
natural language understanding. These models, trained on extensive data, can
generate text, answer complex questions, and even engage in creative tasks.
Combined or chained together, they can accomplish many previously very hard or
time-consuming things in just a few milliseconds per token.

The seminal paper
["Attention Is All You Need"](https://arxiv.org/abs/1706.03762) introduced
attention mechanisms, enabling models to focus on specific data segments, much
like human attention. Coupled with multi-layer perceptrons (MLP),
attention-based transformer LLMs are pattern-finding machines. They take long
text sequences as input, finding the most statistically significant parts of the
sequence to focus on, mixing attention through many neural network layers, and
outputting
[logits](https://developers.google.com/machine-learning/glossary#logits) (bits
representing un-normalized predicted probablities) for predictions (usually the
next token in a sequence, but not always).

# The Double-Edged Sword: Limitations of LLMs

However, every silver lining has a cloud. The structure and training that
produces such extraordinary behavior from the likes of ChatGPT, which also has
some drawbacks.

## The Herculean Task of Keeping Language Models Current

[GPT-4.0 boasts approximately 1.8 trillion parameters](https://medium.com/predict/gpt-4-everything-you-want-to-know-about-openais-new-ai-model-a5977b42e495),
[Meta's LLaMa 2 trained on 2 trillion tokens](https://arxiv.org/abs/2307.09288)
simply for the base model.
[Using millions of dollars](https://www.semianalysis.com/p/the-ai-brick-wall-a-practical-limit)
worth of compute. While trained for a very long time, the released models didn't
reach saturation of perplexity. Meaning that
[LLaMa 2 still has months more of training before it has learned all the word relation concepts in the corpus](https://severelytheoretical.wordpress.com/2023/03/05/a-rant-on-llama-please-stop-training-giant-language-models/).
However, this sheer magnitude is a double-edged sword. Models learn by finding
the steepest direction to improve the loss function. More subtle patterns in the
data will not be the steepest direction until all the word-level patterns are
learned. Larger models will take much longer to learn new subtle concepts as
they have larger parameter spaces to search.

Training these models is not just a matter of time but also of computational
power and the ability to purchase/operate that power. The use of specialized
hardware like TPUs or a Mixture of Experts on distributed NVLink is almost a
given, and the state-of-the-art hardware has sharp edges.

### Evolving Trends

Everything about these vast and growing models is slow to train. However,
language, code bases, and technology are not static; they evolve, influenced by
cultural shifts, technological advancements, and global events.

Updating a model to capture these nuances is not a trivial task. It involves:

1. Scraping new web corpus data that reflects current language trends.
2. Extending training runs with the updated corpus to learn intricate language
   patterns.
3. Fine-tuning the model without overriding the newly acquired patterns.

## The Scaling Challenge of Transformer-Based Machine Learning Models

Transformer-based sequence models have become the cornerstone for many
applications, from natural language processing to computer vision. However,
scaling these models becomes a formidable challenge as they grow in size and
complexity. The crux of the issue lies in the quadratic nature of the attention
mechanism and multi-layer perceptrons (MLPs), which exponentially inflate
computational and memory requirements.

### The Quadratic Nature of Attention Mechanism

The attention mechanism, a pivotal component of transformer models, scales
quadratically with the sequence length n. Specifically, the self-attention
mechanism computes a weighted sum of all input elements, requiring O(n^2) time
and space complexity. This dense matrix math enables the model to capture
long-range dependencies, the computational cost also skyrockets as the model
scales limiting practical sequence lengths.

### The Quadratic Attributes of MLPs

MLPs, another integral part of transformers, also exhibit quadratic attributes.
The hidden layers in an MLP have a time complexity of O(n^2) when the input and
output dimensions are equal. This translates to an exponential surge in memory
requirements, mainly when the model comprises multiple such layers. LLaMa 2 has
32 hiddens layers in each of its 32 attention blocks.

### Impact on Efficiency, Latency, and Memory Bandwidth

The quadratic scaling attributes of both the attention mechanism and MLPs have
far-reaching implications:

1. **Efficiency**: The computational overhead limits the model's efficiency,
   making it less feasible for deployment in resource-constrained environments.
2. **Latency**: Real-time inferencing becomes challenging as the time taken for
   a single forward pass increases exponentially with model size.
3. **Memory Bandwidth**: The memory bandwidth becomes a bottleneck, especially
   when deploying models on hardware with limited memory capabilities.

## Facts stump LLMs

While LLMs have shown prowess in numerous tasks, they are not without their
limitations. For instance, LLMs tend to fall short in tasks such as commonsense
reasoning, as highlighted by the study
"[Tabular Data: Deep Learning is Not All You Need](https://arxiv.org/pdf/2106.03253.pdf)".

> XGBoost outperforms these deep models across the datasets, including the
> datasets used in the papers that proposed the deep models.

This underscores the importance of diversifying model architectures and training
them on specific tasks to cater to the multifaceted needs of modern businesses.

For example, tree-based models like XGBoost and Random Forest have consistently
proven their mettle when it comes to tabular scalar prediction or category
prediction. The research from
"[Why do tree-based models still outperform deep learning on tabular data?](https://arxiv.org/pdf/2207.08815.pdf)"
elucidates the superiority of these models in handling structured data, making
them the state-of-the-art choice for businesses dealing with such datasets.

Time series forecasting is another domain where simpler, specialized models can
outperform more complex architectures like LLMs. Time series data, commonly
found in business scenarios, requires coherent forecasts with some understanding
of cause and effect (even if only seasonality). While LLMs might struggle in
this domain, packages like StatsForecast, equipped with autoregression and
seasonality knowledge, offer a more effective solution. For a more comprehensive
look at different time series prediction tools, look at Microprediction's blog
post titled
"[Fast Python Time-Series Forecasting](https://www.microprediction.com/blog/fast)."
Compared to training and deploying an LLM, these tools are more straightforward,
faster, and more accurate.

## The Need for Speed: Real-Time Machine Learning

Large Language Models (LLMs) are among the most complex and resource-intensive
architectures. While they offer unparalleled capabilities, their size makes them
slower at inference time.

Take the example of self-driving cars. These vehicles rely on real-time image
processing to navigate safely. The latency demands are stringent; there's little
room for delay. Deploying colossal models like LLMs, which require multiple
iterations to compute a result, is impractical.

Personal recommendation systems have also evolved to meet the demands of speed
and efficiency. The
[two-towers model architecture](https://hackernoon.com/understanding-the-two-tower-model-in-personalized-recommendation-systems)
has gained prominence for its ability to pre-compute substantial data. This
architecture allows for
[bulk operations on low cardinality items](https://www.linkedin.com/pulse/personalized-recommendations-iv-two-tower-models-gaurav-chakravorty/),
reducing the computational load during inference time. As a result, only one of
the two towers needs to be computed on the hot path, making the system both
faster and more cost-effective.

### The Cost of Inference: A Business Concern

Inference cost is not just a technical issue; it's a business concern. Companies
must balance the capabilities of a model against the resources required to run
it. In the world of machine learning, bigger is not always better.

## Smaller Model With Less Risky Corpus

Businesses are often faced with the decision of investing in larger models or
focusing on refining their datasets. A recent study titled
"[Scaling Laws for Neural Language Models](https://arxiv.org/pdf/2001.08361.pdf)"
suggests that while larger models can achieve impressive performance, there are
diminishing returns on their efficiency as they scale. Smaller models paired
with meticulously curated datasets can offer a more cost-effective and efficient
solution for many businesses, especially those with limited computational
resources. When free from the noise and potential biases of vast internet
crawls, these datasets can lead to accurate and ethically sound models.

The potential pitfalls of training on vast internet text are highlighted in the
paper
"[On the Dangers of Stochastic Parrots](https://dl.acm.org/doi/pdf/10.1145/3442188.3445922)".
Models like GPT-4 or Microsoft's
[ill fated Tay](https://www.theverge.com/2016/3/24/11297050/tay-microsoft-chatbot-racist),
despite their impressive capabilities, can and do produce
[biased](https://www.cs.princeton.edu/courses/archive/fall22/cos597G/lectures/lec14.pdf),
[toxic](https://arxiv.org/pdf/2009.11462.pdf), or inappropriate content due to
their training data. For
[LLaMa, over 1 trillion of the tokens in the original dataset were from the internet](https://together.ai/blog/redpajama),
which, for all its power, the content of the internet can be of varied quality.
These results and papers underscore the importance of better datasets. By
curating datasets that are representative and free from the less desirable
aspects of the broader internet, businesses can ensure that their models perform
well and align with ethical standards. This approach reduces the
[risk of models producing outputs that could harm a brand's reputation or alienate its customers](https://arxiv.org/abs/2009.11462).

Lastly, the benefits of smaller models extend beyond just ethical
considerations. They are inherently more manageable, making them prime
candidates for instruction training with Reinforcement Learning from Human
Feedback (RLHF) and fine-tuning processes. This agility allows businesses to
adapt their models to changing requirements or new data quickly, ensuring they
remain at the forefront of their industry's AI-driven innovations. In
conclusion, while the allure of larger models is undeniable, a strategic focus
on better datasets and smaller, more agile models can offer businesses a
competitive edge in the long run.

# Where to Next?

So, what's the game plan for the future, you ask? Well, let's not put all our
eggs—or in this case, trillions of parameters—in one basket. Imagine a future
where Large Language Models and transformers are like the Avengers of the AI
world. They're powerful, yes, but even Iron Man needs a little help from
Spider-Man and Doctor Strange now and then. In the same way, our AI systems will
become a smorgasbord of different model architectures and sizes, each bringing
its own superpower to the table. From XGBoost's knack for tabular data to
specialized models that can predict whether it'll rain on your wedding day,
diversity is the spice of machine learning life!

Thank you for sticking with me through this rollercoaster of ones and zeros, and
pros and cons. Remember, in the ever-evolving world of AI, it's not just about
going big or going home. Sometimes, it's about going smart, going diverse, and
going absolutely bonkers with innovation. So, keep your capes on, future AI
Avengers; the best is yet to come!
