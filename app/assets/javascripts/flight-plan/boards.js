FPLAN.boards = {
    show: function() {
        var parent = this;

        $('.open-pull-requests-item').popup({
            inline: true,
            on: 'click'
        });

        $(document).on('click', '.issue-title', function(event) {
            event.preventDefault();
            var target = $(event.target);
            parent._showTicketAjax(target);
        });
    },

    _parseMarkdown: function(text) {
        if (!this.markdownConverter) {
            this.markdownConverter = new showdown.Converter()
            this.markdownConverter.setFlavor('github')
            this.markdownConverter.setOption('openLinksInNewWindow', true);
        }
        return this.markdownConverter.makeHtml(text)
    },

    _showTicketAjax: function(link) {
        $.ajax({
            url: link.data('url')
        }).then(function(data) {
            var modal = $('#applicationModal');
            var modalBody = modal.children('.content').empty();

            var wrapperHtml = $('<div class="ui divided grid ticket-modal">'
                    + '<div class="twelve wide column">'
                        + '<div class="ui feed"></div>'
                    + '</div>'
                    + '<div class="four wide column">'
                        + '<div class="ticket-sidebar">'
                            + '<div class="ui vertical text menu">'
                                + '<div class="item">'
                                    + '<div class="header">Durations</div>'
                                    + '<div class="durations"></div>'
                                + '</div>'
                            + '</div>'
                        + '</div>'
                    + '</div>'
                + '</div>');

            var feed = wrapperHtml.find('.ui.feed')
            var sidebar = wrapperHtml.find('.ticket-sidebar')
            var durations = sidebar.find('.durations')

            modal.find('.header').html(FPLAN.boards._headerHtml(data))

            feed.append(FPLAN.boards._bodyHtml(data));

            $.each(data.ticket.comments, function(index, comment) {
                feed.append(FPLAN.boards._commentHtml(comment));
            })

            $.each(data.state_durations, function(index, state_duration) {
                durations.append(FPLAN.boards._durationHtml(state_duration))
            })

            modalBody.append(wrapperHtml)

            modalBody.scrollTop(0)
            modal.modal('show');
        })
    },

    _headerHtml: function(data) {
        return '<a href="' + data.ticket.html_url + '" target="_blank">'
                + '#' + data.ticket.number
            + '&nbsp;&nbsp;</a>'
            + data.ticket.title;
    },

    _bodyHtml: function(data) {
        return '<div class="event">'
            + '<div class="label">'
            + '</div>'
            + '<div class="content">'
                + '<div class="summary">'
                    + '<a class="user">'
                        + 'unknown author'
                    + '</a>'
                    + ' opened issue '
                    + '<div class="date">'
                        + data.ticket.timestamp + ' ago'
                    + '</div>'
                + '</div>'
                + '<div class="extra text gh-markdown">'
                    + FPLAN.boards._parseMarkdown(data.ticket.body)
                + '</div>'
            + '</div>'
        + '</div>';
    },

    _commentHtml: function(comment) {
        return '<div class="ui divider"></div><div class="event">'
            + '<div class="label">'
                + '<img src="https://github.com/' + comment.author + '.png">'
            + '</div>'
            + '<div class="content">'
                + '<div class="summary">'
                + '<a href="https://github.com/' + comment.author + '" class="user">'
                        + comment.author
                    + '</a>'
                    + ' commented '
                    + '<div class="date">'
                        + comment.timestamp + ' ago'
                    + '</div>'
                + '</div>'
                + '<div class="extra text gh-markdown">'
                    + FPLAN.boards._parseMarkdown(comment.body)
                + '</div>'
            + '</div>'
        + '</div>';
    },

    _durationHtml: function(state_duration) {
        return '<div class="ui green fluid label">'
            + state_duration.name
                + '<div class="detail">'
                    + state_duration.duration
                + '</div>'
            + '</div>';
    }
}
