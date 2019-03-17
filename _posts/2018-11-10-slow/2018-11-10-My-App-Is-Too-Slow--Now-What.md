---
layout: post
tags: [performance]
excerpt_separator: <!--more-->
comments: true
---
You don’t have to be a software engineer for long until you hit into performance issues. The database loads too slow. Calculating the route
takes forever. Remote calls hang. What to do?
<!--more-->
![My App](sloth.jpg)

SQL query optimization? JS packing? Indices? Algorithm optimizations? Multi threading? Change to C++? Cloud? Micro services? Sharding? NoSQL? Remove features? Increase hardware requirements? Kernel optimizations? JIT loading? Load balancing? Remove variables? Use Protobuf? Better Compression? Change libraries? Change frameworks? GC tuning?

There are a lot of ways speed up code and not all of them will be effective or worth the effort. But what’s the best option in your case? This is a vast specialized area where for example all the techniques listed above have their own experts if you happen to need one. Before you go and hire one, let’s go through some steps that may help you decide.

### Step 1: Diagnosis

Diagnosing the problem is the obvious first step. It can be as simple as timing function calls, but usually it’s a better to fire up a profiler, something like the Chrome Developer Tools Profiles Pane or Java Mission Control, whatever the platform you’re on. There are a lot of
p[erformance analysis tools](https://en.m.wikipedia.org/wiki/List_of_performance_analysis_tools) out there so go and find the one that is applicable to your needs. Take the time to learn how to use one and they’ll usually pinpoint you to the worst offender rather quickly.

This is also a good time to spot programming errors like memory leaks.
Those need to be fixed regardless. Look for object counts and allocated
memory and see if the numbers make sense.

It’s almost a certainty that the [Pareto
principle](https://en.wikipedia.org/wiki/Pareto_principle) will hold — 80% of the slowness is caused by 20% of
the code. In fact it’s usually much more extreme than that — a single
often hit function could be the bottle neck for the entire 100k line
code base so most of your effort should go to fix that first.

Often the problem is as obvious as the fix, so grabbing these low
hanging fruit can solve most of your woes. If it’s not obvious how and
what to fix, keep reading.

### Step 2: Understand Your Domain

![Finnish conscripts testing the voting system in 2017](voting.jpg)

Even if something could be done it doesn’t mean it should. Knowing your
domain, the given hardware limitations and the expected load is vital
before you decide to do anything drastic. Are we talking about a single
player game here? A hardware sensor reading app that runs on your
Raspberry Pi? A business app with max 100 users? A web app with millions
of concurrent users? Changing from Ruby to C might make sense on the Pi,
but probably not with your Rails app.

Let’s take the the Finnish Parliament and it’s voting system
problem for example:

> The Finnish parliament upgraded its electronic voting system in the
> early 2000s. In the final phases of testing they found out that when
> enough members pressed their voting buttons at the same time, the
> system couldn’t handle the load and crashed.

In the Finnish Parliament the chair calls for a vote on something, and
you have 200 members of parliament voting for something by pressing one
three options, Jaa (Yes), Ei (No) or Tyhjää (None of the above). They
usually have something like 10 seconds or so to do this. So if you think
about it, the scenario that didn’t work is the most common use
case — most of the members will press their button immediately as the
voting is up.

So what can we learn from this, at least performance wise? Understand
your domain. Changing to a serverless cloud architecture probably won’t
help if the problem is with the electronics, even if the back end was
kinda slow. Aim your goals to match the expected load now and in the
near future. There’s no need to make the voting system work with 10000
concurrent users. The parliament won’t (I hope!) grow to that size. In
fact to set the goal to exactly 200 is fine, maybe throw an extra 20 to
have a margin of error.

Loads aren’t usually this predictable and static. There’s increases and
peaks and that surprise hoard of Reddit front page users. But still,
know your playing field and accept that it might not be
worth it to prepare for everything at once. You’ll never ship if you set
your Android app performance goal to the slowest phone out there. Trust
me, it’s slower than that sloth.

If you have a hundred users and hoping to reach a thousand the measures
you should take now are different compared to getting from thousand to a
million. The latter might require techniques like using micro services
and they will add a huge layer of complexity to the
system with added risk. Getting to a thousand is likely a matter of
optimizing your database queries.

### Step 3: Decide Course of Action

So the app is slow and you’ve diagnosed the problem. It’s that function
that loads the data from the remote database. So how should you proceed?

Here’s a domain agnostic questionnaire to narrow your options:

#### Can I skip doing this completely?

Seriously think about it. Even your ultra optimized algorithm is slower
than my deleted code. Many of the greatest performance tricks like
[adaptive tile
refresh](https://en.wikipedia.org/wiki/Adaptive_tile_refresh) are at their heart ways to avoid doing stuff. Think
about the use case and if it’s not vital, maybe you can do without it,

Maybe some light weight version of it will suffice? Do you really really
need the 7MB js library to load the 10MB SVG company logo that’s 10
pixels across in the corner?

#### Can I move it somewhere less expensive?

Maybe you have a computationally expensive list on the front page. Does
everyone use it? If not, perhaps move it somewhere so only the people
that really need it are inflicted. It can also save cycles on the back
end.

#### Can I do it only once?

Also known as caching. Doing something only once and then using the
result is effective, but it’s also
[hard](https://martinfowler.com/bliki/TwoHardThings.html). Especially if you invent your own caching scheme,
you’ll open a huge can of worms to deal with. Your existing test suite
might also be inadequate to handle it when calls suddenly return
outdated data. Be warned of regressions. Tread carefully and prefer any
existing technologies like
[ehcache](http://www.ehcache.org/)
out there.

If your application has a long chain of computations, also consider
caching the intermediary results. If you have the memory, use it.

#### Can I do it partially?

This can be as simple as paging, or it can be limiting the amount of
data shown to the user and requesting more data if the use requests it.
See also JIT.

#### Can I index it?

Indices are simplified an added data structure that speed up data
retrieval. If your database queries are slow, SQL query optimization
usually involves adding indices. But it can be an added dictionary in
your code that stores keys that speed up results. For example if you
have a graph of cities on a map, there can be an additional
dictionary(the index) of city names that can be used to retrieve the
nodes.

The cost is maintaining the index and this usually means increased
storage requirements and slower writes.

#### Can I JIT?

JIT (just in time) means delaying the loading of the data until it’s
really required. This can be some form of lazy loading in the code (the
object is initialized the moment it’s actually used) or having a
scrolling list that loads more elements when the user scrolls down to
the, such as the
[*RecyclerView*](https://developer.android.com/guide/topics/ui/layout/recyclerview). Almost all modern languages and frameworks have a
variant of lazy loading, so look into it.

#### Can I preload?

The opposite of JIT is loading a chunk data in advance. Is it more
tolerable to have a single long pause as opposed to smaller stutters
here and there? If for example the hardware is limited, constant loading
can be out of the question and a single long wait might be worth it if
the UI is unusable garbage otherwise.

#### Can I do it secretly?

Splash screens. Everyone loves splash screens right? Well that’s not so
secret, but doing stuff on the background when the user does something
else can put the problem under the rug. Things like
[*BackgroundWorkers*](https://docs.microsoft.com/en-us/dotnet/api/system.componentmodel.backgroundworker?view=netframework-4.7.2) are good for this.

The downside is synchronization —does someone else need the result of
the computation? This will inevitably add complexity and introduce fun
risks like dead locks.

#### Can I do it concurrently?

This beast is also called multithreading. Can I split the problem into
parts so that you can solve them in parallel and then gather the
results? This can be very effective, but it’s also hard. Very hard.

Deadlocks, race conditions, Heisenbugs, synchronization issues, thread
safety, testing challenges.. Fun times. If you’re not familiar with this
already, turn back.

#### Can I increase memory/cpu?

Sometimes there’s nothing wrong per se with the app, it just runs out of
resources. If the OS runs out memory and it swaps, it’s going to be
detrimental. Same goes for CPU cycles. If the app doesn’t leak memory,
adding memory is probably the cheapest choice to fix your problems.
There’s a lot to be done optimizing your OS if you know the problem lies
there.

In case of web apps for example, you can also split the load onto
multiple computers and use a load balancer. In the age of cloud
computing, this can also can scale like magic and you do basically
nothing (but pay).

#### Can I guess ahead?

Buffering.. Video is the obvious example, or
[Spectre](https://en.wikipedia.org/wiki/Spectre_%28security_vulnerability%29) err.. I mean branch prediction in CPU architectures.
A combination of doing things secretly and trying to guess what the user
is going to do next.

If you guess wrong, you waste cycles (or create security
vulnerabilities).

#### Can I tolerate errors?

The workable solution to any
[NP-hard](https://en.wikipedia.org/wiki/NP-hardness) problem. Trying to solve it perfectly might be a
fools errand if [good
enough](https://en.wikipedia.org/wiki/Travelling_salesman_problem#Computing_a_solution) but faster solution gets you at 2% distance of the
optimal.

With really big data sets, the [eventual
consistency](https://en.wikipedia.org/wiki/Eventual_consistency) of NoSQL databases is also an example of this. Being
optimistic and fixing the errors later can be a significant performance
boost.

#### Can I optimize the algorithm?

There’s never a shortage of things to do on the algorithm level. For
example, look at the known subclasses of the
[*Collection*](https://docs.oracle.com/javase/8/docs/api/java/util/Collection.html) interface in Java. Do you remember all of them and
know when to use them? Or is everything an *ArrayList* in your app*?* On
top of that there’s stuff like
[fastutil](http://fastutil.di.unimi.it/) if you really need to push it. It’s not uncommon to
see code needlessly doing the same thing over and over and looping
through a long list when a *HashMap* would’ve worked.

There’s a lot to be done on the code level, and if your unit tests are
solid, it should also be relatively safe. Again, YMMV.

#### Can I reduce requests?

Fetching data from a remote server is slow, very slow compare to your
computer memory. The round trip to your data center more than [100
000](https://blog.codinghorror.com/the-infinite-space-between-words/)x slower than to your RAM. If you make a lot of round
trips, can you make a single larger batch request for example?

The downside of batching can be that the round trip time of a single
request can increase, if the batching module waits for more data or the
request size factors into it. YMMV.

#### Can I use a dedicated text searching service?

Does your application have an internal text search that’s slow? Things
like [Lucene](https://lucene.apache.org/core/) can feel like black magic if you have the memory to
spare. Use them if you have the memory to spare.

#### Can I split the database into more manageable chunks?

Also known as
[sharding](https://en.wikipedia.org/wiki/Shard_%28database_architecture%29). If your database has grown to a gigantic size
perhaps this is an option. It comes with the caveat of added complexity.

#### Can I compress it?

Can I use something like
[webpack](https://webpack.js.org/) to
minimize the request load in my web app? Or use zip compression in large
network transfers? You can also look into things like [Protocol
Buffers](https://developers.google.com/protocol-buffers/) if you are sure that the REST JSON overhead is too
much.

#### Can I change the framework or programming language?

I don’t know, can you? Would it help? Unless you’re on the Pi or similar
limited hardware, this should be at the bottom of your list.

#### Can I run serverless?

It solves all these problems and all the cool kids do this, so we should
too, right? Well, maybe. I have no experience of this, tell me how it
went if you do this!

### What Else?

Sometimes the problem is much more hairy — it persists only under
heavier loads harder to reproduce or only on that gremlin infected
machine that looks identical to others. Or you’ve simply run out of the
obvious stuff to optimize. This type of stuff can get very specialized,
you’ll save time by hiring an expert to figure out out. Doing things
like [flame
graphs](http://www.brendangregg.com/flamegraphs.html) can help visualize the painful areas.

Whatever you decide to do, make sure you have tests in place that you
can verify that the changes work and don’t cause regressions. Many of
these techniques can really change the internals quite dramatically,
even if nothing changes on the outside. Change incrementally, one
optimization at a time if possible.

Good Luck!

![(Not) My App](roadrunner.jpg)

By [Tatu Lahtela](https://medium.com/@lahtela) on
[November 10, 2018](https://medium.com/p/44d9791c3736).

Originally release on [Medium](https://medium.com/@lahtela/my-app-is-too-slow-now-what-44d9791c3736)


