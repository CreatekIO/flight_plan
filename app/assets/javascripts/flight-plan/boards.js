FPLAN.boards = {
  show: function() {
    $('.ticket-title').on('click', function(event) {
      event.preventDefault;
      var link = $(event.target)

      $.ajax({
        url: link.attr('href')
      }).success(function(data) {
        var modal = $('#modal');

        modal.find('.modal-title').html(data.title);
        modal.find('.modal-body').text(data.body);
        modal.modal();
      })
    });
  }
}
