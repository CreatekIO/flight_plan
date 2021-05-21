module ApplicationHelper
  def hide_container?
    @hide_container
  end

  def calculate_percentage(number, total)
    return '0%' if total.zero?

    number_to_percentage(
      (number.to_f / total) * 100,
      significant: true,
      precision: 2
    )
  end

  def next_swimlane_tickets_path(board_tickets)
    last = board_tickets.last
    return if last.blank?

    swimlane_tickets_path(last.swimlane_id, after: last.swimlane_sequence)
  end

  def to_or_sentence(collection, &block)
    collection = collection.map { |item| capture { yield(item) }} if block_given?

    to_sentence(
      collection,
      two_words_connector: ' or ',
      last_word_connector: ', or '
    )
  end
end
