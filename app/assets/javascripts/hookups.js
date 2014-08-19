var Hookup = {
    toggle_event_cancel: function() {
        $('#form-hookup-create').slideToggle();
        $('#btn-hookup-new').removeAttr("disabled");
        event.preventDefault()
    },

    toggle_event_immediate: function() {
        $('#form-hookup-create').slideToggle();
        $('#btn-hookup-new').attr("disabled", "disabled");
    },

    setup: function () {
        $('#btn-hookup-new').click(Hookup.toggle_event_immediate);
        $('#btn-cancel-new').click(Hookup.toggle_event_cancel);
        $('#btn-hookup-new').removeAttr("disabled");
    }
}
$(document).on('ready page:load', Hookup.setup)
