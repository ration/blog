---
layout: single
---
![Hereee’s a problem](jack_here.jpg)

Everyone loves to lambaste the endless drudgery of the typical workday.
Meetings, coworkers interrupting, inadequate equipment, Reddit.. It
feels like the time goes to everything but the task at hand.

But let’s put all that aside for a moment. You’re on your zone. No
distractions or interruptions in sight. Not even Reddit. We spend a
substantial amount of time not writing code but on the browser looking
for answers. Answers to questions you didn’t want to ask. The dumbest
thing can take days to solve, drive you mad and make you think about
your career choices. But what are we looking for? Why are there at any
given time 50 tabs open, half of which are to Stack Overflow?

I recently wrote an [app](https://github.com/ration/betman) from start
to finish and I wanted to answer this question. The project was a
developers dream as it was totally greenfield, there was only one person
to blame (me) and I had a very specific list of features to do and they
were unlikely to change or increase. I did the full stack (Kotlin,
Spring, Bootstrap, Angular) — everything from project creation to
deploying it in the cloud in a Docker container. It took about two
months of calendar time, mostly an hour or two here and there when my
newborn allowed it (=slept).

The stack was a typical in the sense that it contained something very
familiar to me (Spring), some with limited knowledge (Kotlin, Angular,
Bootstrap,) to totally new territory such as the Google
Cloud and Spring Webflux. It also had some elements that I added for
pure academic interest (JWT tokens, Exposed).

So where does the time go making something like this? Basically all
programming tasks begin with divide and conquer — you design the overall
architecture and then split the problem into more manageable parts and
start tackling them one by one. Database. UI views. REST request
handling. Authentication. CSS. On an on. This type of division feels
like second nature for any experienced programmer and life feels like
worth living when you get to it. Then come the surprises. The “where’s
my emergency whisky”-stuff that make you pull your hair out (I’m bald).

Things that shouldn’t be a problem that take two days to resolve type of
problems drive you nuts. Examples don’t work. The build suddenly fails.
Configuration options don’t seem to work. The patch release to your
dependency breaks everything. Bizarre error
codes.

![[xkcd 1024](https://xkcd.com/1024/)](xkcd-1024.png)



Out of interest I wrote down the biggest surprise problems that I had on
the way that took more than two hours to resolve and drove me a bit
deeper towards the brink of madness. Many of these could be their own
post and save some hair for the next sucker out there, but I’ll briefly
go through some of them and the resolution.

-----

#### JWT Tokens with Spring Boot Didn’t Work

There are
[instructions](https://auth0.com/blog/implementing-jwt-authentication-on-spring-boot/)
out there, but the session data didn’t persist inside Spring. I always
was the anonymous user according to Spring no matter how much I
authenticated myself. I debugged the internals of Spring request
handling for the longest time to no avail until I figured it out. Turns
out it’s a bad idea to use @Autowire to the pass the Spring
[SecurityContext](https://docs.spring.io/spring-security/site/docs/4.2.4.RELEASE/apidocs/org/springframework/security/core/context/SecurityContext.html)
to classes. Use the *SecurityContextHolder* **every time.**

**Lesson Learned**: If you’re having trouble with libraries and are
lucky enough to have all of the code at your disposal, look at the code.
Stare and debug at it long enough and you might figure it out.

Maybe I should try a job as a car mechanic?

#### How do I return data from Exposed transactions?

([Exposed](https://github.com/JetBrains/Exposed)is an ORM for Kotlin).
In the framework you wrap database operations into transactions like
this:

``` 
transaction {
 val dao = UserDao.find{ name eq someName }
 dao.password = newPass
 return toPojo(dao) // Error
}
```

I wanted to return something from that transaction (POJO with updated
data), but the return keyword was no allowed. I had no idea what even to
Google to fix this.

**Lesson Learned**: Kotlin Higher-Order functions return the last
statement and that transaction is just a method with a lambda parameter.
So the last example would be just:

``` 
transaction {
 val dao = UserDao.find{ name eq someName }
 dao.password = newPass
 toPojo(dao)
}
```

For some inexplicable reason my brain just didn’t make the connection to
Kotlin [lambdas](https://kotlinlang.org/docs/reference/lambdas.html) and
I thought this was some other magic. All I really would’ve needed to do
is look how the *transaction* function is
defined and internalize it properly.

> There’s no such thing as magic, only things you don’t understand. If
> the magic fails you stop and figure it out before using it.
> Frantically googling for a solution to a problem you don’t understand
> won’t get you anywhere.

Maybe there’s opportunity in brewing?

#### Angular Routing Errors in Spring Routing

In Spring you use the *WebSecurityConfigurerAdapter* class to declare
security rules how each URI is resolved, which can bypass the session
authentication etc. But if I used routing in Angular i.e. different
controllers with different URIs. Spring got a hissy fit and spat out
errors.

**Lesson Learned:** Turns out you need something like this:

This make sure all requests (that don’t match the other Spring routing
rules) are forwarded to *index.html*, and from thereon to the correct
Angular controller. Google will give you all kinds of obsolete no longer
working versions of this.

Maybe a plumber?

#### Spring JUnit Testing Woes

I had two problems at the same time, the Spring Context loading didn’t
quite work the way I wanted and autowiring fields was flaky. The context
didn’t load configuration files written in YML for example, especially
in integration tests. And field injection didn’t quite work with a test
Context.

**Lesson Learned:** Turns out [you can’t use YML in tests
properties](https://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/test/context/TestPropertySource.html)
(look at supported formats). Also [don’t inject fields if you can avoid
it](https://www.vojtechruzicka.com/field-dependency-injection-considered-harmful/).
Better yet, avoid Spring in tests altogether if you can get away with
it.

Garbage man?

#### Configuration via ConfigurationProperties

Partly related to the previous one,
[ConfigurationProperties](https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-external-config.html),
while cool, were an utter pain to get working. Again the magic factor
was a bit too high — quite often the defined configuration POJO just
said null and I didn’t have a clue what to do. Them not working in unit
tests didn’t help either.

**Lesson Learned:** Endless tinkering sometimes is all you can do.

How about distilling?

#### Multitable Queries in Exposed

Again Exposed woes. I had no clue how to write queries that touch
multiple tables. Finally I asked [Stack
Overflow](https://stackoverflow.com/questions/50143775/how-do-i-search-from-multiple-tables-with-dao)
and got an answer.

**Lesson Learned:** DAO framework magic that generate SQL queries are a
failure by design. I felt like this before I even started and here I was
again. Maybe this time they’ll just work I said to my self. Nope. You
have a clean and fast SQL query in your head, but you’re spending hours
endlessly massaging the DAO layer hoping it would generate it correctly
and not be horrendously slow. Things like Android
[Room](https://developer.android.com/topic/libraries/architecture/room)
are simply superior.

Wine making perhaps?

#### Karma refused to work with PhantomJS

Unit tests fail if I run against the PhantomJS browser engine. I would
get get something like `[object ErrorEvent]` and the tests would
randomly fail.

**Lesson Learned:** The JavaScript ecosystem is a mess. But I knew that
already.

![I wonder if you can even throw a newer flat screen through a window or
will just bounce](tv.jpg)



How about organized crime?

#### Security Vulnerability in Hoek

I had no idea what Hoek is, but Github complained that it has a
vulnerability open so I spent hours and hours to figure out how to [fix
it.](https://github.com/angular/angular-cli/issues/10480) That issue is
closed but I’m not convinced that it has been fixed.

**Lesson Learned:** JavaScript is mess. Security problems in your
dependencies are always also your problems.

Live under a bridge and live on social security?

#### Angular 5-\>6

In the middle of my development push Angular 6 was released. In my
infinite wisdom I thought the upgrade should be a breeze, I have only a
few hundred lines of Angular code, right? I also thought I’ll bite the
bullet and not use the compatibility layer since the code base was
small. I ran the auto upgrade thingy and …problems. Here’s a list:

  - I used Observable.of and Rx stream operators heavily, both were not
    upgraded properly. Especially [stream pipe()
    change](https://github.com/ReactiveX/rxjs/blob/6.2.0/MIGRATION.md#pipe-syntax)
    was painful.

  - Imports were fiddled around with. I think they’re just messing with
    us. They are aware that this breaks everything, right?

  - WebStorm lost the ability to run tests

**Lesson learned**: **Use extreme caution when using anything latest and
greatest.** Maybe all of these were avoided if I had just waited for
things to settle.

Farming?

#### TypeScript Compilation Error

Suddenly everything on the Angular side broke down. I
got:

``` 
ERROR in src/app/auth.interceptor.ts(6,2): error TS2345: Argument of type 'typeof AuthInterceptor' is not assignable to parameter of type '({ providedIn: Type<any> | "root"; } & ValueSansProvider)
| ({ providedIn: Type<any> | "root"; } ...'.
Type 'typeof AuthInterceptor' is not assignable to type '{ providedIn: Type<any> | "root"; } & ClassSansProvider'.
Type 'typeof AuthInterceptor' is not assignable to type '{ providedIn: Type<any> | "root"; }'.
Property 'providedIn' is missing in type 'typeof AuthInterceptor'.
```

Google didn’t offer any help. Yes, the error was on line 6 in the
*auth.interceptor.ts* but I didn’t see it. I rewrote the class and
diffed the results to find out the error. I missed parentheses in
@Injectable annotation.

**Lesson Learned:** I immediately saw the error after a break. Check
your fundamentals when “Hello World\!” level stuff doesn’t
work.

![A hobo perhaps?](jump.gif)

#### Json List Types in Kotlin

I had troubles mapping JSON lists to Kotlin Pojos. Basically [this
problem](https://stackoverflow.com/questions/39679180/kotlin-call-java-method-with-classt-argument).
While I did figure it out, it looked so ugly and flaky I opted for plan
B and just changed the JSON instead.

**Lesson Learned:** Workaround is always an option.

Park ranger?

#### Spring Integration tests with Gradle 4

I had no luck doing Spring Integration tests, all I got was:

``` 
java.lang.NoClassDefFoundError: org/hamcrest/SelfDescribing
```

Everywhere I looked everything was still at Gradle 3 and of no help.

**Lesson Learned:** You can always open more search tabs. Endless
googling got me to the correct magic:

``` 
configurations {
   integrationTestImplementation.extendsFrom testImplementation 
   integrationTestRuntimeOnly.extendsFrom testRuntimeOnly
}
```

It’s still magic. I don’t even know what to read to unmagic it.

Professional golfer? That’s still an option at age 37 right?

#### My Rest controller returns HTML

One of my rest endpoints stubbornly returned HTML instead of JSON. I
laboriously went through the annotations and couldn’t understand what
was going on. I added all kinds of the accept and return type
annotations but nothing worked.

I missed that the class was annotated with @Controller instead of the
correct @RestController. Sigh.

**Lesson Learned:** Again with the fundamentals.

Construction? I hear they’re in demand.

#### Howto Return 403 if User Has No Access

Spring has an interface called
[*UserDetailsService*](https://docs.spring.io/spring-security/site/docs/4.2.6.RELEASE/apidocs/org/springframework/security/core/userdetails/UserDetailsService.html)
that can be used to define how the user is loaded from the database for
example. But I couldn’t figure out how to differentiate authentication
to authorization, i.e. the user is known but not allowed in said page. I
got
[nowhere](https://stackoverflow.com/questions/36427923/spring-boot-security-how-to-return-http-403-after-successful-authentication-b).
I hacked a solution at the front end side.

**Lesson Learned:** Failure is always an option.

Nannying? Oh wait I do that already.

#### Computer Meltdown

My old Surface Pro 3 started to buckle under the pressure so I bought a
[new computer](https://www.msi.com/Laptop/GS65-Stealth-Thin-8RF). My
unit test execution time went from 15 seconds to 2. No more total
IntelliJ freezes. I could run WebStorm, IDEA and the app in an Docker
container at the same time and still had memory to spare.

**Lesson Learned:** Solving problems with money is always a good idea,
assuming you have
it.

![Urge to kill fading..](fading.jpg)

#### Angular Route Parameters

I needed to send parameters between controllers. Sure there are [guides
out
there](https://angular-2-training-book.rangle.io/handout/routing/routeparams.html),
but again the magic factor was too high. It felt like if strayed a
millimeter from the examples and suddenly the `route.params` was empty
or something. This was doubly true with Karma tests. Why is this
[RouterTestingModule](https://angular.io/api/router/testing/RouterTestingModule)
now required when it wasn’t before kind of stuff. Especially how to set
parameters to controllers seemed to differ wildly. I finally resolved it
to something like this to pass paramaters to the controllers:

``` 
TestBed.configureTestingModule({
  declarations: [GroupComponent],
  imports: [FormsModule, RouterTestingModule.withRoutes([]), HttpClientTestingModule],
  providers: [GroupsService, UserService, AlertService, AuthenticationService,
    [GroupComponent, {
      provide: ActivatedRoute,
      useValue: {snapshot: {params: {'group': '123'}}}
    }]]
}).compileComponents();
```

About as ugly as you can get as this gets passed to every test but hey,
it works.

**Lesson Learned:** Again with the magic. Bleeding edge magic with
limited documentation.

-----

There was more, but I think you get the
point.

![I wish I were Jack](jack.jpg)



By [Tatu Lahtela](https://medium.com/@lahtela) on
[October 26, 2018](https://medium.com/p/cba8794f0995).

Originally posted on [Medium](https://medium.com/@lahtela/the-madness-that-is-programming-cba8794f0995)

Exported from [Medium](https://medium.com) on March 4, 2019.

