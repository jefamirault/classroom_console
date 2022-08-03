// $(document).ready(function() {
//     $('table').DataTable({
//         "pageLength": 25
//     });
// } );

document.addEventListener("turbolinks:load", function() {
    $('table').DataTable({
        "pageLength": 25,
        "aaSorting": []
    });
})

$(document).on('shown.bs.modal','#subscribeModal', function() {
    $('#userEmail').focus();
});

$(function(){
    $('form').on('submit', function(){
        $(this).find('button[type=submit]').attr('disabled', true);
    });
});

$(window).on('load', function () {
    $('#loading').hide();
})

$(document).on('click', '.slow', function(){
    $('#loading').show();
});
