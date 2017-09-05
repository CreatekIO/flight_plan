FPLAN.boards = {
  show: function() {
    $('#ticketModal').on('show.bs.modal', function(event) {
      var link = $(event.relatedTarget);

      $.ajax({
        url: link.data('url')
      }).success(function(data) {
        var modal = $('#ticketModal');
        var modalBody = modal.find('.modal-body')

        modal.find('.modal-title').html(data.title);
        modalBody.html('<div class="well">' + data.body + '</div>');
        $.each(data.comments, function(index, comment) {
          modalBody.append(
            '<div class="well">'
              + comment.body
              + '<br><span class="label label-danger">'
              + comment.author
              + '</span>'
              + '</div>');
        })
      })
    });
  }
}
