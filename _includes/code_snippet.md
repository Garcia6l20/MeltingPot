<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/clipboard.js/1.5.3/clipboard.min.js"></script>

{% assign code = include.code %}
{% assign language = include.language %}

``` {{ language }}
{{ code }}
```
{% assign nanosecond = "now" | date: "%N" %}
<textarea id="code-{{ nanosecond }}" style="display:none;">{{ code | xml_escape }}</textarea>

<button class="btn copy-to-clipboard" id="copybutton-{{ nanosecond }}" data-clipboard-target="#code-{{ nanosecond }}" data-clipboard-action="copy" data-id="textarea">
  <img src="https://clipboardjs.com/assets/images/clippy.svg" width="13" alt="Copy to clipboard">
</button>

<script>
//var copybutton = document.getElementById('copybutton-{{ nanosecond }}');
var clipboard = new Clipboard('.copy-to-clipboard');

clipboard.on('success', function(e) {
    console.log(e);
});
clipboard.on('error', function(e) {
    console.error(e);
});
</script>
