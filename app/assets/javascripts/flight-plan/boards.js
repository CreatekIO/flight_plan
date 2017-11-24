FPLAN.boards = {
    show: function() {
        var parent = this;

        $(document).on('click', '.issue-title', function(event) {
            event.preventDefault();
            var target = $(event.target);
            parent._showTicketAjax(target);
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
        }).then(function(data) {
            var modal = $('#applicationModal');
            var modalBody = modal.children('.content').empty()

            modal.find('.header').html(data.ticket.title);
            modalBody.html(FPLAN.boards._headerHtml(data));

            $.each(data.ticket.comments, function(index, comment) {
                modalBody.append(FPLAN.boards._commentHtml(comment));
            })

            modalBody.append('<div class="ui feed">');
            $.each(data.state_durations, function(index, state_duration) {
                modalBody.append(FPLAN.boards._durationHtml(state_duration));
            })
            modalBody.append('</div>');
            modal.modal('show');
        })
    },

    _headerHtml: function(data) {
        return FPLAN.boards._parseMarkdown(data.ticket.body);
    },

    _commentHtml: function(comment) {
        return '<div class="event">'
            + '<div class="content">'
                + '<div class="summary">'
                    + '<div class="user">'
                        + comment.author
                    + '</div>'
                + '</div>'
                + '<div class="extra text">'
                    + FPLAN.boards._parseMarkdown(comment.body) 
                + '</div>'
            + '</div>'
        + '</div>';
    },

    _durationHtml: function(state_duration) {
        return '<span class="label label-success">'
            + state_duration.name
            + ': '
            + state_duration.duration
            + '</span>';
    }

}
