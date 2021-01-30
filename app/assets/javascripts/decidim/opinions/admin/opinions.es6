// = require_self
$(document).ready(function () {
  let selectedOpinionsCount = function() {
    return $('.table-list .js-check-all-opinion:checked').length
  }

  let selectedOpinionsNotPublishedAnswerCount = function() {
    return $('.table-list [data-published-state=false] .js-check-all-opinion:checked').length
  }

  window.selectedOpinionsCountUpdate = function() {
    const selectedOpinions = selectedOpinionsCount();
    const selectedOpinionsNotPublishedAnswer = selectedOpinionsNotPublishedAnswerCount();
    if(selectedOpinions == 0){
      $("#js-selected-opinions-count").text("")
    } else {
      $("#js-selected-opinions-count").text(selectedOpinions);
    }

    if(selectedOpinions >= 2) {
      $('button[data-action="merge-opinions"]').parent().show();
    } else {
      $('button[data-action="merge-opinions"]').parent().hide();
    }

    if(selectedOpinionsNotPublishedAnswer > 0) {
      $('button[data-action="publish-answers"]').parent().show();
      $('#js-form-publish-answers-number').text(selectedOpinionsNotPublishedAnswer);
    } else {
      $('button[data-action="publish-answers"]').parent().hide();
    }
  }

  let showBulkActionsButton = function() {
    if(selectedOpinionsCount() > 0){
      $("#js-bulk-actions-button").removeClass('hide');
    }
  }

  window.hideBulkActionsButton = function(force = false) {
    if(selectedOpinionsCount() == 0 || force == true){
      $("#js-bulk-actions-button").addClass('hide');
      $("#js-bulk-actions-dropdown").removeClass('is-open');
    }
  }

  window.showOtherActionsButtons = function() {
    $("#js-other-actions-wrapper").removeClass('hide');
  }

  window.hideOtherActionsButtons = function() {
    $("#js-other-actions-wrapper").addClass('hide');
  }

  window.hideBulkActionForms = function() {
    $(".js-bulk-action-form").addClass('hide');
  }

  if ($('.js-bulk-action-form').length) {
    window.hideBulkActionForms();
    $("#js-bulk-actions-button").addClass('hide');

    $("#js-bulk-actions-dropdown ul li button").click(function(e){
      e.preventDefault();
      let action = $(e.target).data("action");

      if(action) {
        $(`#js-form-${action}`).submit(function(){
          $('.layout-content > .callout-wrapper').html("");
        })

        $(`#js-${action}-actions`).removeClass('hide');
        window.hideBulkActionsButton(true);
        window.hideOtherActionsButtons();
      }
    })

    // select all checkboxes
    $(".js-check-all").change(function() {
      $(".js-check-all-opinion").prop('checked', $(this).prop("checked"));

      if ($(this).prop("checked")) {
        $(".js-check-all-opinion").closest('tr').addClass('selected');
        showBulkActionsButton();
      } else {
        $(".js-check-all-opinion").closest('tr').removeClass('selected');
        window.hideBulkActionsButton();
      }

      selectedOpinionsCountUpdate();
    });

    // opinion checkbox change
    $('.table-list').on('change', '.js-check-all-opinion', function (e) {
      let opinion_id = $(this).val()
      let checked = $(this).prop("checked")

      // uncheck "select all", if one of the listed checkbox item is unchecked
      if ($(this).prop("checked") === false) {
        $(".js-check-all").prop('checked', false);
      }
      // check "select all" if all checkbox opinions are checked
      if ($('.js-check-all-opinion:checked').length === $('.js-check-all-opinion').length) {
        $(".js-check-all").prop('checked', true);
        showBulkActionsButton();
      }

      if ($(this).prop("checked")) {
        showBulkActionsButton();
        $(this).closest('tr').addClass('selected');
      } else {
        window.hideBulkActionsButton();
        $(this).closest('tr').removeClass('selected');
      }

      if ($('.js-check-all-opinion:checked').length === 0) {
        window.hideBulkActionsButton();
      }

      $('.js-bulk-action-form').find(".js-opinion-id-"+opinion_id).prop('checked', checked);
      selectedOpinionsCountUpdate();
    });

    $('.js-cancel-bulk-action').on('click', function (e) {
      window.hideBulkActionForms()
      showBulkActionsButton();
      showOtherActionsButtons();
    });
  }
});
