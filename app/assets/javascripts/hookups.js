var Hookup = {
    toggle_event_cancel: function() {
        $('#form-hookup-create').slideToggle();
        $('#btn-hookup-new').disabled = false;
        event.preventDefault()
    },

    toggle_event_immediate: function() {
        $('#form-hookup-create').slideToggle();
        document.getElementById('btn-hookup-new').disabled = true;
    },

    setup: function () {
        $('#btn-hookup-new').click(Hookup.toggle_event_immediate);
        $('#btn-cancel-new').click(Hookup.toggle_event_cancel);
        $('#btn-hookup-new').disabled = false;
    }
}
$(document).on('ready page:load', Hookup.setup)
