
window.Bubbles = () ->
	# standard variables accessible to
	# the rest of the functions inside Bubbles
	data = []
	node = null
	label = null
	removeB = null
	width = null
	height = null
	activeNode = null
	margin = {top: 5, right: 0, bottom: 0, left: 0}
	# largest size for our bubbles
	maxRadius = 45

	# this scale will be used to size our bubbles
	rScale = d3.scale.sqrt().range([10,maxRadius])
	
	# I've abstracted the data value used to size each
	# into its own function. This should make it easy
	# to switch out the underlying dataset
	rValue = (d) -> parseInt(d.count)

	# function to define the 'id' of a data element
	#  - used to bind the data uniquely to the force nodes
	#   and for url creation
	#  - should make it easier to switch out dataset
	#   for your own
	idValue = (d) -> d.name

	# function to define what to display in each bubble
	#  again, abstracted to ease migration to 
	#  a different dataset if desired
	textValue = (d) -> d.name

	# constants to control how
	# collision look and act
	collisionPadding = 4
	minCollisionRadius = 12

	# variables that can be changed
	# to tweak how the force layout
	# acts
	# - jitter controls the 'jumpiness'
	#  of the collisions
	jitter = 0.5

	# ---
	# tweaks our dataset to get it into the
	# format we want
	# - for this dataset, we just need to
	#  ensure the count is a number
	# - for your own dataset, you might want
	#  to tweak a bit more
	# ---
	transformData = (rawData) ->
		rawData.forEach (d) ->
			d.count = parseInt(d.count)
			rawData.sort(() -> 0.5 - Math.random())
		rawData

	# ---
	# tick callback function will be executed for every
	# iteration of the force simulation
	# - moves force nodes towards their destinations
	# - deals with collisions of force nodes
	# - updates visual bubbles to reflect new force node locations
	# ---
	tick = (e) ->
		dampenedAlpha = e.alpha * 0.1
		
		# Most of the work is done by the gravity and collide
		# functions.
		node.selectAll(".bubble-node")
			.each(gravity(dampenedAlpha))
			.each(collide(jitter))
			.attr("transform", (d) -> "translate(#{d.x},#{d.y})")

		# As the labels are created in raw html and not svg, we need
		# to ensure we specify the 'px' for moving based on pixels
		label.selectAll(".bubble-label")
			.style("left", (d) -> ((margin.left + d.x) - d.dx / 2) + "px")
			.style("top", (d) -> ((margin.top + d.y) - d.dy / 2) + "px")

		if activeNode?
			showRemoveButton(activeNode)

	# The force variable is the force layout controlling the bubbles
	# here we disable gravity and charge as we implement custom versions
	# of gravity and collisions for this visualization
	force = d3.layout.force()
		.gravity(0)
		.charge(0)
		.on("tick", tick)

	# ---
	# Creates new chart function. This is the 'constructor' of our
	#  visualization
	# Check out http://bost.ocks.org/mike/chart/ 
	#  for a explanation and rational behind this function design
	# ---
	chart = (selection) ->
		selection.each (rawData) ->
			width = $(this).width() - margin.left - margin.right
			height = $(this).height() - margin.top - margin.bottom 

			d3.layout.force().size([width, height])

			# first, get the data in the right format
			data = transformData(rawData)
			# setup the radius scale's domain now that
			# we have some data
			maxDomainValue = d3.max(data, (d) -> rValue(d))
			minDomainValue = Math.max(d3.min(data, (d) -> rValue(d))-parseInt(maxDomainValue*20/199), 0)
			rScale.domain([minDomainValue, maxDomainValue])

			# a fancy way to setup svg element
			svg = d3.select(this).selectAll("svg").data([data])
			svgEnter = svg.enter().append("svg")
			svg.attr("width", width + margin.left + margin.right )
			svg.attr("height", height + margin.top + margin.bottom )
			
			# node will be used to group the bubbles
			node = svgEnter.append("g").attr("id", "bubble-nodes")
				.attr("width", width)
				.attr("height", height)


			# label is the container div for all the labels that sit on top of 
			# the bubbles
			# - remember that we are keeping the labels in plain html and 
			#  the bubbles in svg
			label = d3.select(this).selectAll("#bubble-labels").data([data])
				.enter()
				.append("div")
				.attr("id", "bubble-labels")

			update()

			# TODO: refresh the bubbles when window is resized
			d3.select(window).on ".resize.bubble", null
			d3.select(window).on "resize.bubble", () => 
				width = $(this).width() - margin.left - margin.right
				height = $(this).height() - margin.top - margin.bottom 
				d3.layout.force().size([width, height])
				svg.attr("width", width + margin.left + margin.right )
				svg.attr("height", height + margin.top + margin.bottom )
				node.attr("width", width).attr("height", height)
				force.start()

	# ---
	# update starts up the force directed layout and then
	# updates the nodes and labels
	# ---
	update = () ->
		# add a radius to our data nodes that will serve to determine
		# when a collision has occurred. This uses the same scale as
		# the one used to size our bubbles, but it kicks up the minimum
		# size to make it so smaller bubbles have a slightly larger 
		# collision 'sphere'
		data.forEach (d,i) ->
			d.forceR = Math.max(minCollisionRadius, rScale(rValue(d)))

		# start up the force layout
		force.nodes(data).start()

		# call our update methods to do the creation and layout work
		updateNodes()
		updateLabels()

	# ---
	# updateNodes creates a new bubble for each node in our dataset
	# ---
	updateNodes = () ->
		# here we are using the idValue function to uniquely bind our
		# data to the (currently) empty 'bubble-node selection'.
		# if you want to use your own data, you just need to modify what
		# idValue returns
		xNodes = node.selectAll(".bubble-node").data(data, (d) -> idValue(d))

		# we don't actually remove any nodes from our data in this example 
		# but if we did, this line of code would remove them from the
		# visualization as well
		xNodes.exit().remove()

		nodeEnter = xNodes.enter().append("g")
            .attr("class", "node")
            .call(force.drag);

		# nodes are just links with circles inside.
		# the styling comes from the css
		nodeEnter.append("a")
			.attr("class", (d) -> "bubble-node trending-#{d.trending}")
			.attr("data-bubble-name", (d) -> encodeURIComponent(idValue(d)))
			.attr("xlink:href", (d) -> "/analysis/trends/t/#{encodeURIComponent(idValue(d))}")
			.call(force.drag)
			.call(connectEvents)
			.append("circle")
			.attr("r", (d) -> rScale(rValue(d)))

	# ---
	# updateLabels is more involved as we need to deal with getting the sizing
	# to work well with the font size
	# ---
	updateLabels = () ->
		# as in updateNodes, we use idValue to define what the unique id for each data 
		# point is
		labels = label.selectAll(".bubble-label").data(data, (d) -> idValue(d))

		labels.exit().remove()

		# labels are anchors with div's inside them
		# labelEnter holds our enter selection so it 
		# is easier to append multiple elements to this selection
		labelEnter = labels.enter().append("a")
			.attr("class", "bubble-label")
			.attr("data-bubble-name", (d) -> encodeURIComponent(idValue(d)))
			.attr("href", (d) -> "/analysis/trends/t/#{encodeURIComponent(idValue(d))}")
			.call(force.drag)
			.call(connectEvents)

		labelEnter.append("div")
			.attr("class", "bubble-label-name")
			.text((d) -> textValue(d))

		labelEnter.append("div")
			.attr("class", "bubble-label-value")
			.text((d) -> rValue(d))

		# label font size is determined based on the size of the bubble
		# this sizing allows for a bit of overhang outside of the bubble
		# - remember to add the 'px' at the end as we are dealing with 
		#  styling divs
		labels
			.style("font-size", (d) -> Math.max(8, rScale(rValue(d) / 2)) + "px")
			.style("width", (d) -> 2.5 * rScale(rValue(d)) + "px")

		# interesting hack to get the 'true' text width
		# - create a span inside the label
		# - add the text to this span
		# - use the span to compute the nodes 'dx' value
		#  which is how much to adjust the label by when
		#  positioning it
		# - remove the extra span
		labels.append("span")
			.text((d) -> textValue(d))
			.each((d) -> d.dx = Math.max(2.5 * rScale(rValue(d)), this.getBoundingClientRect().width))
			.remove()

		# reset the width of the label to the actual width
		labels
			.style("width", (d) -> d.dx + "px")
	
		# compute and store each nodes 'dy' value - the 
		# amount to shift the label down
		# 'this' inside of D3's each refers to the actual DOM element
		# connected to the data node
		labels.each((d) -> d.dy = this.getBoundingClientRect().height)

	# ---
	# custom gravity to skew the bubble placement
	# ---
	gravity = (alpha) ->
		# start with the center of the display
		cx = width / 2
		cy = height / 2
		# use alpha to affect how much to push
		# towards the horizontal or vertical
		ax = alpha / 4
		ay = alpha

		# return a function that will modify the
		# node's x and y values
		(d) ->
			d.x += (cx - d.x) * ax
			d.y += (cy - d.y) * ay

	# ---
	# custom collision function to prevent
	# nodes from touching
	# This version is brute force
	# we could use quadtree to speed up implementation
	# (which is what Mike's original version does)
	# ---
	collide = (jitter) ->
		# return a function that modifies
		# the x and y of a node
		(d) ->
			data.forEach (d2) ->
				# check that we aren't comparing a node
				# with itself
				if d != d2
					# use distance formula to find distance
					# between two nodes
					x = d.x - d2.x
					y = d.y - d2.y
					distance = Math.sqrt(x * x + y * y)
					# find current minimum space between two nodes
					# using the forceR that was set to match the 
					# visible radius of the nodes
					minDistance = d.forceR + d2.forceR + collisionPadding

					# if the current distance is less then the minimum
					# allowed then we need to push both nodes away from one another
					if distance < minDistance
						# scale the distance based on the jitter variable
						distance = (distance - minDistance) / distance * jitter
						# move our two nodes
						moveX = x * distance
						moveY = y * distance
						d.x -= moveX
						d.y -= moveY
						d2.x += moveX
						d2.y += moveY

	# ---
	# adds mouse events to element
	# ---
	connectEvents = (d) ->
		d.on("mouseover", mouseover)
		d.on("mouseout", mouseout)

	# ---
	# hover event
	# ---
	mouseover = (d) ->
		activeNode = d
		node.classed("bubble-hover", (p) -> p == d)
		showRemoveButton(d)
		if window.bubleTimeout
			clearTimeout(window.bubleTimeout)


	# ---
	# remove hover class
	# ---
	mouseout = (d) ->
		node.classed("bubble-hover", false)
		window.bubleTimeout = setTimeout () ->
			d3.selectAll('.bubble-remove').remove()
			activeNode = null
		, 200

	showRemoveButton = (d) ->
		if activeNode
			button = d3.select('.bubble-remove')
			if button.empty()
				button = d3.select('#bubble-labels').insert('a', ":first-child")
					.attr('class', 'bubble-remove')
					.attr('title', 'Remove this word')
					.on("click", () -> removeNode(activeNode) )
					.on("mouseover", () -> mouseover(activeNode) )
					.on("mouseout", mouseout )

			button.attr('href', '#')
				.attr('style', "top: #{(margin.left+d.y-7)-(d.forceR * Math.cos(315))}px; left: #{(margin.left+d.x-7)+(d.forceR * Math.sin(315))}px")


	removeNodeREMOVE = (d) ->
		d3.event.preventDefault()
		data = data.filter (e) -> e isnt d
		node = node.filter (n) -> n.name isnt d.name
		d3.selectAll("[data-bubble-name=\"#{d.name}\"]").remove()
		d3.selectAll('.bubble-remove').remove()
		activeNode=null
		force.start()
	
	removeNode = (d) ->
		d3.event.preventDefault()
		data = data.filter (e) -> e isnt d
		force.nodes force.nodes().filter (n) -> n.name isnt d.name
		d3.selectAll('.bubble-remove').remove()
		activeNode=null
		update()

	# ---
	# public getter/setter for jitter variable
	# ---
	chart.jitter = (_) ->
		if !arguments.length
			return jitter
		jitter = _
		force.start()
		chart

	# ---
	# public getter/setter for height variable
	# ---
	chart.height = (_) ->
		if !arguments.length
			return height
		height = _
		chart

	# ---
	# public getter/setter for width variable
	# ---
	chart.width = (_) ->
		if !arguments.length
			return width
		width = _
		chart

	# ---
	# public getter/setter for radius function
	# ---
	chart.r = (_) ->
		if !arguments.length
			return rValue
		rValue = _
		chart

	chart.addNode = (d) ->
		d.count = parseInt(d.count)
		d.forceR = Math.max(minCollisionRadius, rScale(rValue(d)))
		force.nodes().push d
		update()

	# final act of our main function is to
	# return the chart function we have created
	return chart

# ---
# Helper function that simplifies the calling
# of our chart with it's data and div selector
# specified
# ---
window.plotData = (selector, data, plot) ->
	d3.select(selector)
		.datum(data)
		.call(plot)

# # ---
# # jQuery document ready.
# # ---
# $ ->
# 	# create a new Bubbles chart
# 	plot = Bubbles()

# 	# ---
# 	# function that is called when
# 	# data is loaded
# 	# ---
# 	display = (data) ->
# 		plotData("#vis", data, plot)

# 	# we are storing the current text in the search component
# 	# just to make things easy
# 	key = decodeURIComponent(location.search).replace("?","")
# 	text = texts.filter((t) -> t.key == key)[0]

# 	# default to the first text if something gets messed up
# 	if !text
# 		text = texts[0]

# 	# select the current text in the drop-down
# 	$("#text-select").val(key)

# 	# bind change in jitter range slider
# 	# to update the plot's jitter
# 	d3.select("#jitter")
# 		.on "input", () ->
# 			plot.jitter(parseFloat(this.output.value))

# 	# bind change in drop down to change the
# 	# search url and reset the hash url
# 	d3.select("#text-select")
# 		.on "change", (e) ->
# 			key = $(this).val()
# 			location.replace("#")
# 			location.search = encodeURIComponent(key)

# 	# set the book title from the text name
# 	d3.select("#book-title").html(text.name)

# 	# load our data
# 	d3.csv("data/#{text.file}", display)