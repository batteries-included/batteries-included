# Batteries Included Thesis

There's a need for an integrated software platform with all the parts of a modern tech stack pre-configured to work together, tuned, and operated hands off. Well constructed infrastructure can be a force multiplier for the business, but it requires lots of moving pieces that integrate together, smoothly, stably, and scalably to create something that's more than the parts. These platforms are complex and hard to maintain without extensive knowledge that few have learned the hard way. Though very few companies relish the chance to build the back end infrastructure that is needed in the modern business landscape; instead they want to focus on building the differentiated parts of their business

## Machine Learning

The current and upcoming needs of businesses will include machine learning. All that's needed is a dataset and a desire for: an accurate prediction, some distilled understanding, or repeatable content creation. What will be the the most likely value of a business metric in the future? What's the most likely price of a dozen eggs next week? How likely is it that someone does some action? What important information is in pictures, videos, or text? Can you translate this language into anther? Machine Learning can do that. The opportunities are there now for businesses, and even more will exist in the future.

While tractable ML opportunities exist now, now, there's no easy way for most individuals in a company to apply machine learning to their data and get a repeatable, reliable, business changing result. Large parts of most companies' infrastructure isn't ready to even attempt. There's a wide gap from where many current companies are (data in excel, unstable infrastructure, database with no easy access to exploration, no monitoring) and the proven run away success seen by ML pioneer companies. We should guide our customers towards proven best practices like easy repeatable experimentation notebooks, automatically re-trainable models, pulling data for ML from reliable infrastructure, all monitored operated and deployed automatically. There aren't many companies that have used cutting edge machine learning day in and day out to power their business at scale; there's an opportunity to lead the market with an ML friendly platform.

## Supporting Cases

### Hyper-Scalers

The hyper-scalers all have this as their superpower and we can see the evidence of this power in their acquisitions. Take a rising app that's having some scaling troubles, one of the large prepared companies acquires them on the cheap. Then the company will send landing engineers to throw battle tested versions of whatever is needed with automated failure, better networking, and containerized ops at the problems; suddenly the app is more stable.

Shortly after the acquisition has stabilized, the usage of stable infrastructure will expand until there's an ease of moving data and processes from one place to anther. At that point it will be possible and easy to use cutting edge ML and move the business $$. This isn't because every engineer at FAANG is so smart that they are the only ones able to do ML well. It's because they have infrastructure that's already there, ready for scaling issues, and is prepared for real good ML.

### AWS/Cloud Computing

Cloud computing has taken the world by storm. Ease of use and elasticity are two often cited advantages. Cloud's ease of use has lead many companies to reach for an AWS product even if there's a slightly better alternative in open source. Speed of iteration is so much faster when there's a web UI that only requires a few clicks to spin up a new service. Compare that finding an open source solution, packaging it up, deploying it, monitoring, alerting, and scaling it. A one stop shop means that users don't have to remember how to search for the start of the process. It's always go to the same webpage and go form there.

However most cloud computing doesn't lead the user well. Every option is provided; a veritable cornucopia of choice. So much choice that it's easy to choose incorrectly and not know it for a long time.

## Boiling the Ocean

### Open Source

A platform play can seem daunting and like we have to create all the software that Google or Amazon have ever written. Additionally it would seem too daunting and impossible to develop such a large system in a reasonable time with a reasonable team. However the good thing is that most needed large systems have been built already in open source. We can greatly increase our velocity by taking the already proven open source technologies, like many FAANG do, and build on top of those.

### Sell along the way

The platform provides compounding power when built; it also provides this with a partial set of headline services. That allows us to build a small part of the platform and then iterate as we get customer feedback, much the same that AWS started out. We have to have start with enough insights in the platform for the sum of the part to be greater than the whole. The rest will follow in an iterative manner.

## Self Hosting

There's a whole set of customers that want this but can't use AWS/GKE/Azure because their data is too private. Banks, Insurance companies, medical companies, hedge funds, etc. These companies are well funded and need all of the features of the cloud, but they are unable to use the public cloud. That means that this is a market with less competition and wealthy customers. It's a market ripe for new solutions.

Cloudera, Gitlab, and RedHat are all great examples of companies that embrace the self hosting while generating good recurring revenue.

Cloud is not cheap when compared to a 5 year ownership of hardware along with depreciation. CapEX vs OpEX can make buying your own servers very very price competitive. So we can use this fact to sell to price conscious customers.

## No one sells what you want

### Cloud

Imagine you are a leader at a company that has a problem with software infrastructure. You want someone to make everything easier for you. So you search around for a solution and find the cloud. Open up the a leading cloud provider and you will find close to 200 different services; many are only slightly different from others, all are complex with hundreds of settings, none are easy to operate. Now you have to lean deep technical information about vendor specific technology, before being able to pay the cloud provider for the service that's closest to what you need.

The cloud didn't sell you the solution. In essence this amounts to telling you:

> You have a problem; the cloud can solve it for you as long as you spend years learning the problem space first, and dedicate operational resources to keep it running in an on going manner.

 Companies have to be their own sales associate, and they end up getting a good but not ideal solution.

### No Cloud

Now imagine that same company doesn't want to or can't use the public cloud. Instead of a list of services there are thousands of open source projects, hundreds of different SaaS companies, and more consulting providers to choose from. Your choice is even harder, but also no solution give you more than one service. You are responsible for matching the problem to the solution (picking software or SaaS), describing the solution wanted (writing the consulting contract), coordinating how all of the different services/solutions are interoperable (configuring everything), and ongoing operation.
