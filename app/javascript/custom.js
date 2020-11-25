$(document).on('shown.bs.modal','#subscribeModal', function() {
    $('#userEmail').focus();
});

$(function(){
    $('form').on('submit', function(){
        $(this).find('button[type=submit]').attr('disabled', true);
    });
});
