---
title: 'Are LLMs always the answer?'
excerpt:
  LLMs dominate AI, but are they always the answer? Learn how targeted models
  and refined datasets can offer more nimble and effective solutions.
publishDate: 2024-07-07
tags: ['AI', 'LLM', 'NLP']
image: ./covers/post-5.jpg
draft: true
---

[Large Language Models (LLMs)](https://aws.amazon.com/what-is/large-language-model/)
have been all the rage recently -- models like
[GPT-4](https://openai.com/research/gpt-4),
[PaLM](https://arxiv.org/abs/2204.02311),
[LLaMa 2](https://arxiv.org/abs/2307.09288),
[LLama 3](https://arxiv.org/abs/2407.21783) and many others, have emerged as
groundbreaking and disruptive innovations. Their ability to generate human-like
text, answer complex questions, and even engage in creative tasks has changed
our approach to natural language processing.

Despite their impressive capabilities, it's essential to consider the nuances
and trade-offs involved in scaling LLMs. Historically, progress in machine
learning has often been achieved by increasing model parameters, moving from 1
million to 400 billion parameters in a short span of years. This approach, while
effective, comes with its own set of challenges.

In this article, we'll be exploring the limitations of LLMs and argue for a more
nuanced approach to AI adoption and development, considering the trade-offs
between model size, efficiency, and specialization.

## The Rise of Large Language Models

The roots of LLMs stretch back to the 20th century. However, the seminal paper
["Attention Is All You Need"](https://arxiv.org/abs/1706.03762), which
introduced the _transformer_ architecture, marked a significant turning point.
This breakthrough allowed models to focus on specific parts of input data,
similar to human attention. Coupled with multi-layer perceptrons (MLPs), these
attention-based models became powerful pattern-finding machines capable of
processing long text sequences and making precise predictions.

LLMs take long text sequences as input, finding the most statistically
significant parts of the sequence to focus on, mixing attention through many
neural network layers, and outputting
[logits](https://developers.google.com/machine-learning/glossary#logits) (bits
representing un-normalized predicted probabilities) for predictions (usually the
next token in a sequence, but not always).

The results are impressive—models like GPT-4, with its estimated 1.8 trillion
parameters, and LLaMa 2, trained on 2 trillion tokens, have pushed the
boundaries of what natural language AI is capable of. From code generation to
creative writing, these models have demonstrated remarkable proficiency in many
tasks, often matching or surpassing human performance in just a few milliseconds
per token.

## A Double-Edged Sword: Limitations of LLMs

However, every silver lining has a cloud, and LLMs are no exception. The
structure and training process that produces such extraordinary behavior also
introduces some noteworthy drawbacks.

Training these behemoths is an appropriately Herculean task,
[requiring millions of dollars](https://www.semianalysis.com/p/the-ai-brick-wall-a-practical-limit)
worth of computing power. Even with such resources, models like
[LLaMa 2 haven't reached saturation in their training](https://severelytheoretical.wordpress.com/2023/03/05/a-rant-on-llama-please-stop-training-giant-language-models/),
meaning they still have months more to go before fully learning all the word
relation concepts in their corpus.

This massive scale introduces a paradox: larger models can capture more
intricate patterns but take much longer to learn new, subtle concepts. Models
learn by finding the steepest direction to improve the loss function. More
subtle patterns in the data will not be in the steepest direction until all the
word-level patterns are learned. As a result, larger models take much longer to
learn new subtle concepts, as they have larger parameter spaces to search.

Training these models is not just a matter of time but also of computational
power and the ability to purchase/operate that power. The use of specialized
hardware like TPUs or a Mixture of Experts on distributed NVLink is almost a
given, and the state-of-the-art hardware has sharp edges.

## Evolving Trends and Staying Relevant

The challenge doesn't end with initial training. Language, code bases, and
technology are not static; they evolve constantly, influenced by cultural
shifts, technological advancements, and global events. For LLMs to remain
relevant, they need to keep up with these changes, a task that grows more
complex as the models increase.

Updating a model to capture these nuances is far from trivial, involving:

- Scraping new web corpus data that reflects the aforementioned world
  developments.
- Running additional training cycles with the updated corpus to learn intricate
  new language patterns without losing previously acquired knowledge.
- Carefully adjusting the model to incorporate new information without
  overriding or corrupting existing patterns.
- Extensive testing to ensure the updated model maintains performance across all
  previous tasks while improving on targeted areas.

This process is not only time-consuming but also incredibly resource-intensive.
For a model like GPT-4 or LLaMa 3, even a minor update could require weeks of
computation time and significant financial investment.

Moreover, there's always the risk of introducing new biases or errors during the
update process. The rapidly changing nature of language and knowledge poses a
significant challenge to LLMs' "bigger is better" philosophy.

When a massive model completes its initial training, parts of its knowledge
could be outdated. This lag between training and deployment becomes more
pronounced as models grow larger, potentially limiting their real-world
applicability in fast-moving domains like technology or current events.

## The Scaling Challenge

As transformer-based models grow in size and complexity, they face significant
scaling challenges. Two core components of these models—the attention mechanism
and multi-layer perceptrons (MLPs)—scale quadratically with sequence length,
leading to exponential increases in computational costs and memory requirements.

The self-attention mechanism computes a weighted sum of all input elements,
requiring O(n^2) time and space complexity, where n is the sequence length. This
dense matrix math enables the model to capture long-range dependencies, but the
computational cost skyrockets as the model scales, limiting practical sequence
lengths.

The hidden layers in an MLP have a time complexity of O(n^2) when the input and
output dimensions are equal. This translates to an exponential surge in memory
requirements, primarily when the model comprises multiple such layers. For
instance, LLaMa 3 8B has 32 hidden layers in addition to its 32 attention
blocks.

The quadratic scaling attributes of both these components have far-reaching
implications:

- The computational overhead limits the model's efficiency, making it less
  feasible for deployment in resource-constrained environments.
- Real-time inferencing becomes challenging as the time taken for a single
  forward pass increases exponentially with model size.
- The memory bandwidth becomes a bottleneck, especially when deploying models on
  hardware with limited memory capabilities.

## When Facts Stump LLMs

While LLMs have shown prowess in numerous tasks, they often fall short in those
requiring common sense reasoning or handling structured data. Studies have shown
that simpler, specialized models can outperform LLMs in specific domains:

- Tree-based models like XGBoost and Random Forest consistently outperform deep
  learning models on tabular data, as highlighted in the study
  ["Tabular Data: Deep Learning is Not All You Need"](https://arxiv.org/pdf/2106.03253.pdf).
- Specialized tools like StatsForecast, equipped with autoregression and
  seasonality knowledge offers more effective solutions for time-series data
  than general-purpose LLMs. The research from
  "[Why do tree-based models still outperform deep learning on tabular data?](https://arxiv.org/pdf/2207.08815.pdf)"
  elucidates the superiority of these models in handling structured data, making
  them the state-of-the-art choice for businesses dealing with such datasets.

> For a more comprehensive look at different time series prediction tools, check
> out Microprediction's blog post
> "[Fast Python Time-Series Forecasting](https://www.microprediction.com/blog/fast)."

These tools are leaner, faster, and more accurate than training and deploying an
LLM.

## The Need for Speed: Real-Time Machine Learning

LLMs are among the most complex and resource-intensive architectures. While they
offer unparalleled capabilities, their size makes them slower at inference time.

In many real-world applications, speed is crucial. Self-driving cars, for
instance, rely on real-time image processing where even milliseconds of delay
can be critical. The size and complexity of LLMs make them impractical for such
time-sensitive tasks.

Inference cost is not just a technical issue; it's a business concern. Companies
must balance a model's capabilities against the resources required to run it. In
the world of machine learning, bigger is not always better.

Personal recommendation systems, for instance, have also evolved to meet speed
and efficiency demands. The
[two-towers model architecture](https://hackernoon.com/understanding-the-two-tower-model-in-personalized-recommendation-systems)
has gained prominence for its ability to pre-compute substantial data. This
architecture allows for
[bulk operations on low cardinality items](https://www.linkedin.com/pulse/personalized-recommendations-iv-two-tower-models-gaurav-chakravorty/),
reducing the computational load during inference time. As a result, only one of
the two towers needs to be computed on the hot path, making the system both
faster and more cost-effective.

## Smaller Models With Less Risky Corpus

A recent study titled
"[Scaling Laws for Neural Language Models](https://arxiv.org/pdf/2001.08361.pdf)"
suggests that while larger models can achieve impressive performance, efficiency
often tapers off as they scale. Smaller models paired with meticulously curated
datasets can offer a more cost-effective and efficient solution for many
businesses, especially those with limited computational resources.

The potential pitfalls of training on vast internet text are highlighted in the
paper
"[On the Dangers of Stochastic Parrots](https://dl.acm.org/doi/pdf/10.1145/3442188.3445922)".
Models like GPT-4 or Microsoft's
[ill-fated Tay](https://www.theverge.com/2016/3/24/11297050/tay-microsoft-chatbot-racist),
despite their impressive capabilities, can and do produce
[biased](https://www.cs.princeton.edu/courses/archive/fall22/cos597G/lectures/lec14.pdf)
or [inappropriate content](https://arxiv.org/pdf/2009.11462.pdf) due to their
training data. For
[LLaMa, over 1 trillion of the tokens in the original dataset came straight from the internet](https://together.ai/blog/redpajama),
which can be inconsistent. These results and papers underscore the importance of
better datasets.

By curating datasets that are representative and free from the less desirable
aspects of the broader internet, businesses can ensure that their models perform
well and align with ethical standards. This approach reduces the
[risk of models producing outputs that could harm a brand's reputation or alienate its customers](https://arxiv.org/abs/2009.11462).

Lastly, the benefits of smaller models extend beyond just ethical
considerations. They are inherently more manageable, making them prime
candidates for instruction training with
[Reinforcement Learning from Human Feedback (RLHF)](https://aws.amazon.com/what-is/reinforcement-learning-from-human-feedback/)
and fine-tuning processes. This agility allows businesses to quickly adapt their
models to changing requirements or new data, ensuring they remain at the
forefront of their industry's AI-driven innovations.

While the allure of ever-larger language models is undeniable, it's crucial to
recognize that they are not a one-size-fits-all solution. The future of AI does
not solely lie in building bigger models but also in developing smarter, more
efficient ones tailored to specific tasks and domains.
