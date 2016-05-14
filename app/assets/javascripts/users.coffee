# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$('.users.get_cards').ready ->
	card_num = 0
	max_num = 8
	card_ids = []
	card_srcs = []

	$('#card_count').text('0/8')
	$('.card_field').on 'click', ->
		src = $(this).find('img').attr('src')
		name = $(this).find('b').text()
		id = $(this).attr('data-id')

		return if (src in card_srcs) || card_num > max_num - 1
		
		card_num += 1
		card_srcs.push src
		card_ids.push id
		$('#card_count').text(card_num + '/' + max_num)
		add_card src, name

	add_card = (src, name) ->
		$li = $('<li class="have_card" style="width:100px;margin:0 8px"></li>')
		html = """
			<div class='thumbnail' style='margin-bottom:0'>
				<img src="#{src}" style='width:100%'>
			</div> 
			<div class='caption text-center'>
				<b>#{name}</b>
			</div>
		"""
		$li.html(html)
		$li.appendTo( $('ul.have_cards') ).fadeIn(500)

