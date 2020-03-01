<h2>{{ site.data.indexlist.docs_list_title }}</h2>
<ul>
   {% for item in site.data.indexlist.docs %}
      <li class="{% if item.url == page.url %}active{% endif %}">
        <a href="{{ item.url }}">{{ item.title }}</a>
      </li>
   {% endfor %}
</ul>

## Using conan packages

Declaring depencies to conan packages are made by using the `conan_requires`
function.

```cmake
conan_requires(<requirements> [BUILD] <build> [OPTIONS] <options> [REPOSITORIES] <repositories>)
```

Arguments:
  - requirements: List conan references  
    eg.: *fmt/6.1.0*, *boost/1.71.0*...

Options:
  - BUILD: Select conan build behaviour  
    eg.: *missing*, *outdated*, *never*  
    see: [conan install documentation](https://docs.conan.io/en/latest/reference/commands/consumer/install.html)

  - REPOSITORIES: List of additional repositories, specified by their NAME and URL  
    eg.: *NAME bincrafter URL https://api.bintray.com/conan/bincrafters/public-conan*

## Generating conan package

```cmake
conan_package(
  AUTHOR <author>
  LICENSE <license>
  URL <url>
  TOPICS <topics>
  DESCRIPTION <description>
  BUILD_MODULES <build_modules>
)
```
