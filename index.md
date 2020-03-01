> The <a href="https://en.wikipedia.org/wiki/Melting_pot">melting pot</a> is a monocultural metaphor for a heterogeneous society becoming more homogeneous, the different elements "melting together" with a common culture [...].

<h2>{{ site.data.indexlist.docs_list_title }}</h2>
<ul>
   {% for item in site.data.indexlist.docs %}
      <li class="{% if item.url == page.url %}active{% endif %}">
        <a href="{{ item.url }}">{{ item.title }}</a>
      </li>
   {% endfor %}
</ul>

## Quick start

### From starter template

1. Go the [starter repository](https://github.com/Garcia6l20/MeltingPot-starter).
2. Select a starting branch.
3. Click on *Use template* button.

### Code upgrade

1. Put a copy of the config file at the root of your project direclty:
```bash
cd <path_to_root_dir>
curl -O https://raw.githubusercontent.com/Garcia6l20/MeltingPot/v0.1.x/dist/.melt_options
```

2. Add folowing lines at the top of your root cmake project:
```cmake
if(NOT EXISTS "${CMAKE_BINARY_DIR}/MeltingPot.cmake")
  message(STATUS "Downloading MeltingPot.cmake from https://github.com/Garcia6l20/MeltingPot")
  file(DOWNLOAD "https://raw.githubusercontent.com/Garcia6l20/MeltingPot/v0.1.x/dist/MeltingPot.cmake" "${CMAKE_BINARY_DIR}/MeltingPot.cmake")
endif()
include(${CMAKE_BINARY_DIR}/MeltingPot.cmake)
```

{%- capture code -%}
if(NOT EXISTS "${CMAKE_BINARY_DIR}/MeltingPot.cmake")
  message(STATUS "Downloading MeltingPot.cmake from https://github.com/Garcia6l20/MeltingPot")
  file(DOWNLOAD "https://raw.githubusercontent.com/Garcia6l20/MeltingPot/v0.1.x/dist/MeltingPot.cmake" "${CMAKE_BINARY_DIR}/MeltingPot.cmake")
endif()
include(${CMAKE_BINARY_DIR}/MeltingPot.cmake)
{%- endcapture -%}

{% include code_snippet.md code=code language='cmake' %}
