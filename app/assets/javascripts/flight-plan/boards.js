FPLAN.boards = {
    show: function() {
        var parent = this;
        $('#applicationModal').on('show.bs.modal', function(event) {
            var relatedTarget = $(event.relatedTarget);
            if(relatedTarget.data('hook').length > 0) {
                eval('parent.' + relatedTarget.data('hook') + '(relatedTarget)')
            }
        });
    },

    _parseMarkdown: function(text) {
        var converter = new showdown.Converter() 
        converter.setOption('tasklists', true);
        converter.setOption('simpleLineBreaks', true);
        return converter.makeHtml(text);
    },

    _showTicketAjax: function(link) {
        $.ajax({
            url: link.data('url')
        }).success(function(data) {
            var modal = $('#applicationModal');
            var modalBody = modal.find('.modal-body')

            modal.find('.modal-title').html(data.ticket.title);
            modalBody.html(
                '<div class="well">' 
                    + FPLAN.boards._parseMarkdown(data.ticket.body)
                    + '</div>'
            );
            $.each(data.ticket.comments, function(index, comment) {
                modalBody.append(
                    '<div class="well">'
                        + FPLAN.boards._parseMarkdown(comment.body) 
                        + '<br><span class="label label-danger">'
                        + comment.author
                        + '</span>'
                        + '</div>'
                );
            })
            $.each(data.state_durations, function(index, state_duration) {
                modalBody.append(
                    '<span class="label label-success">'
                        + state_duration.name
                        + ': '
                        + state_duration.duration
                        + '</span>'
                );
            })
        })
    }
}
