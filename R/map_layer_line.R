mapdeckLineDependency <- function() {
	list(
		htmltools::htmlDependency(
			"line",
			"1.0.0",
			system.file("htmlwidgets/lib/line", package = "mapdeck"),
			script = c("line.js")
		)
	)
}


#' Add line
#'
#' The Line Layer renders raised lines joining pairs of source and target coordinates
#'
#' @inheritParams add_arc
#' @param stroke_colour variable or hex colour to use as the ending stroke colour
#'
#' @examples
#' \dontrun{
#'
#' key <- read.dcf("~/Documents/.googleAPI", fields = "MAPBOX")
#'
#' url <- 'https://raw.githubusercontent.com/plotly/datasets/master/2011_february_aa_flight_paths.csv'
#' flights <- read.csv(url)
#' flights$id <- seq_len(nrow(flights))
#' flights$stroke <- sample(1:3, size = nrow(flights), replace = T)
#'
#' mapdeck( token = key, style = 'mapbox://styles/mapbox/dark-v9', pitch = 45 ) %>%
#' 	add_line(
#' 		data = flights
#' 		, layer_id = "line_layer"
#' 		, origin = c("start_lon", "start_lat")
#' 		, destination = c("end_lon", "end_lat")
#' 		, stroke_colour = "airport1"
#' 		, stroke_width = "stroke"
#' 	)
#' }
#'
#' @export
add_line <- function(
	map,
	data = get_map_data(map),
	layer_id,
	origin,
	destination,
	id = NULL,
	stroke_colour = NULL,
	stroke_width = NULL,
	digits = 6,
	palette = viridisLite::viridis
) {

	objArgs <- match.call(expand.dots = F)

	## if origin && destination == one column each, it's an sf_encoded
	## else, it's two column, which need to be encoded!
	if ( length(origin) == 2 && length(destination) == 2) {
		## lon / lat columns
		data[[ origin[1] ]] <- googlePolylines:::encode(
			data[, origin, drop = F ]
			, lon = origin[1]
			, lat = origin[2]
			, byrow = T
		)
		data[[ destination[1] ]] <- googlePolylines:::encode(
			data[, destination, drop = F ]
			, lon = destination[1]
			, lat = destination[2]
			, byrow = T
		)

		objArgs[['origin']] <- origin[1]
		objArgs[['destination']] <- destination[1]

	} else if (length(origin) == 1 && length(destination) == 1) {
		## encoded
		data <- normaliseMultiSfData(data, origin, destination)
		data[[origin]] <- unlist(data[[origin]])
		data[[destination]] <- unlist(data[[destination]])

	} else {
		stop("expecting lon/lat origin destinations or sfc columns")
	}

	## parameter checks


	## end parameter checks

	allCols <- lineColumns()
	requiredCols <- requiredLineColumns()

	colourColumns <- shapeAttributes(
		fill_colour = NULL
		, stroke_colour = stroke_colour
		, stroke_from = NULL
		, stroke_to = NULL
	)

	shape <- createMapObject(data, allCols, objArgs)

	# print(head(shape))
	pal <- createPalettes(shape, colourColumns)

	colour_palettes <- createColourPalettes(data, pal, colourColumns, palette)
	colours <- createColours(shape, colour_palettes)

	if(length(colours) > 0) {
		shape <- replaceVariableColours(shape, colours)
	}

	# print(head(shape))
	requiredDefaults <- setdiff(requiredCols, names(shape))

	if(length(requiredDefaults) > 0){
		shape <- addDefaults(shape, requiredDefaults, "line")
	}

	shape <- jsonlite::toJSON(shape, digits = digits)

	map <- addDependency(map, mapdeckLineDependency())
	invoke_method(map, "add_line", shape, layer_id)
}


requiredLineColumns <- function() {
	c("stroke_colour", "stroke_width")
}

lineColumns <- function() {
	c("origin", "destination",
		"stroke_width", "stroke_colour")
}

lineDefaults <- function(n) {
	data.frame(
		"stroke_colour" = rep("#440154", n),
		"stroke_width" = rep(1, n),
		stringsAsFactors = F
	)
}