$(() => {
  const $content = $(".picker-content"),
      pickerMore = $content.data("picker-more"),
      pickerPath = $content.data("picker-path"),
      toggleNoOpinions = () => {
        const showNoOpinions = $("#opinions_list li:visible").length === 0
        $("#no_opinions").toggle(showNoOpinions)
      }

  let jqxhr = null

  toggleNoOpinions()

  $(".data_picker-modal-content").on("change keyup", "#opinions_filter", (event) => {
    const filter = event.target.value.toLowerCase()

    if (pickerMore) {
      if (jqxhr !== null) {
        jqxhr.abort()
      }

      $content.html("<div class='loading-spinner'></div>")
      jqxhr = $.get(`${pickerPath}?q=${filter}`, (data) => {
        $content.html(data)
        jqxhr = null
        toggleNoOpinions()
      })
    } else {
      $("#opinions_list li").each((index, li) => {
        $(li).toggle(li.textContent.toLowerCase().indexOf(filter) > -1)
      })
      toggleNoOpinions()
    }
  })
})
