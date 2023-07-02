function SourceInspect(csrfToken) {
  return {
    mounted() {
      let sourceInspectorHook = this;
      let element = sourceInspectorHook.el;
      element.addEventListener("contextmenu", (contextMenuEvent) => {
        // Get the HTML element that has been clicked
        var target = contextMenuEvent.currentTarget;
        // Extract the file and line from the HTML attributes
        var file = target.dataset.sourceInspectorFile;
        var line = target.dataset.sourceInspectorLine;
    
        // Ask the backend to open the file using an editor using
        // an old-dashined HTTP request.
        fetch("/_source_inspector_goto_source", {
          method: "POST",
          mode: "cors",
          cache: "no-cache",
          credentials: "same-origin",
          headers: {
            'x-csrf-token': csrfToken,
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          redirect: "follow",
          referrerPolicy: "no-referrer",
          // Encode the parameters using URI encoding
          body: ("file=" + encodeURI(file) + "&line=" + encodeURI(line))
        })
    
        // Make sure the event doesn't bubble up to the parent elements
        contextMenuEvent.stopPropagation()
        contextMenuEvent.preventDefault()
        return false
      })
    }
  }
}

export default SourceInspect