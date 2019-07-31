---
layout: post
title:  Multiple Spring Properties with Lists
date:   2019-07-31 09:43:15 +0300
tags: [spring,java]
---


Say you have multiple configuration files you want to use to when starting the application. One with
some general settings shared by multiple instances and one with specific to this instance:

general.yaml:
{% highlight yaml %}
configuration:
    servers:
      - name: "My awesome server"
      - password: "Very secret"
{% endhighlight %}
app.yaml:
{% highlight yaml %}
configuration:
   name: awesome-app
{% endhighlight %}

With @ConfigurationProperties you can automatically bind this configuration to a POJO:

{% highlight java %}
@Configuration
@ConfigurationProperties("configuration")
public class Config {
  private String name;
  private List<Server> servers = new ArrayList<>();
  public String getName() {
    return name;
  }
  public void setName(String name) {
    this.name = name;
  }
  public List<Server> getServers() {
    return servers;
  }
  public void setServers(List<Server> servers) {
    this.servers = servers;
  }
  public static class Server {
    private String password;
    private String name;
    public String getPassword() {
      return password;
    }
    public void setPassword(String password) {
      this.password = password;
    }
    public String getName() {
      return name;
    }
    public void setName(String name) {
      this.name = name;
    }
  }
}
{% endhighlight %}


Starting the app with these two configuration files is simply a matter of adding them to the `spring.config.location`
list: {% highlight bash %} java -Dspring.config.location=~/general.yaml,~/app.yaml my.app.app.AppApplication {% endhighlight %}

Done and done! Off to the races.

## Lists in Multiple Files

Let's say you would like to have something like this:

general.yaml:
{% highlight yaml %}
configuration:
   servers: 
   - name: http://some.server
   - name: http://second.server
{% endhighlight %} 

Then you have another file that that contains the passwords, perhaps generated from a key vault or something:

secrets.yaml:
{% highlight yaml %}
configuration:
   servers: 
   - password: mysecret
   - password: second-password
{% endhighlight %} 


Depending on the order/priority, either the name or the password will be null. Dang. Sadly this doesn't work ([as per
doc](https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-external-config.html#boot-features-external-config-complex-type-merge)):

> When a List is specified in multiple profiles, the one with the highest priority (and only that one)

So what now? Well you can rethink your design decisions do this some other way. 

You still want to do this? Well one way would be to
disable @ConfigurationProperties, merge the multiple configuration sources into a single PropertySource and feed that to
the
[Binder](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/context/properties/bind/Binder.html)
manually.

Ok let's first create a method that does the binding and merging for a generic prefix:

{% highlight java %}
  public static <T> T bindClassFromAllProperties(Class<T> klass, ConfigurableEnvironment env, String prefix) {
    // Take all properties that start with out prefix 
    Set<String> keys = StreamSupport
        .stream(env.getPropertySources().spliterator(), false)
        .filter(ps -> ps instanceof EnumerablePropertySource)
        .map(ps -> ((EnumerablePropertySource) ps).getPropertyNames())
        .flatMap(Arrays::stream)
        .filter(propName -> propName.startsWith(prefix))
        .collect(Collectors.toSet());
    Properties properties = new Properties();
    // Take the value with out keys from env, this will preserve priorities
    keys.forEach(key -> properties.put(key, Objects.requireNonNull(env.getProperty(key))));
    ConfigurationPropertySource propertySource = new MapConfigurationPropertySource(properties);
    return new Binder(propertySource).bind(prefix, klass).get();
  }
{% endhighlight %}


So now we can use this in a @Bean definition:
{% highlight java %}
  @Bean
  public Config loadConfig(ConfigurableEnvironment env,
      ApplicationContext context) {
    return bindClassFromAllProperties(Config.class, env, "configuration");
  }
{% endhighlight %}

Now just remove @Configuration and @ConfigurationProperties annotations from your configuration class so the bean is
used to create the Config object. 
