$(() => {
  const $form = $(".opinion_form_admin");

  if ($form.length > 0) {
    const $opinionCreatedInMeeting = $form.find("#opinion_created_in_meeting");
    const $opinionMeeting = $form.find("#opinion_meeting");

    const toggleDisabledHiddenFields = () => {
      const enabledMeeting = $opinionCreatedInMeeting.prop("checked");
      $opinionMeeting.find("select").attr("disabled", "disabled");
      $opinionMeeting.hide();

      if (enabledMeeting) {
        $opinionMeeting.find("select").attr("disabled", !enabledMeeting);
        $opinionMeeting.show();
      }
    };

    $opinionCreatedInMeeting.on("change", toggleDisabledHiddenFields);
    toggleDisabledHiddenFields();

  }
});
