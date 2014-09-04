var EventScheduler = {
    init: function () {
        $('.datepicker').datepicker({
            format: 'yyyy-mm-dd'
        });
        $('.timepicker').timepicker();
        $('#event_repeats').on('change', this.toggle_event_options);
        $('#event_repeat_ends').on('change', this.toggle_repeat_ends_on);
        this.toggle_event_options();
        this.toggle_repeat_ends_on();
    },

    toggle_event_options: function () {
        $('.event_option').hide();
        switch ($('#event_repeats').val()) {
            case 'never':
                // Nothing
                break;

            case 'weekly':
                $('#repeats_options').show();
                $('#repeats_weekly_options').show();
                break;
        }
    },

    toggle_repeat_ends_on: function () {
        switch ($('#event_repeat_ends').val()) {
            case 'never':
                $('#event_repeat_ends_on').hide();
                break;
            case 'on':
                $('#event_repeat_ends_on').show();
                break;
        }
    }
}

$(document).ready(function () {
    EventScheduler.init();
});