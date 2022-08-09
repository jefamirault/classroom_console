let dataTable = null

document.addEventListener("turbolinks:load", function() {
    dataTable = $('table').DataTable({
        "pageLength": 50,
        "aaSorting": []
    });
    $('[data-toggle="tooltip"]').tooltip()
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
    $('[data-toggle="tooltip"]').tooltip()
    document.addEventListener("turbolinks:before-cache", function() {
        if (dataTable !== null) {
            dataTable.destroy()
            dataTable = null
        }
    })
});

$(document).on('click', '.slow', function(){
    $('#loading').show();
});
