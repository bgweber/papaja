#' Prepare table for printing
#'
#' Formats \code{matrices} and \code{data.frames} to report them as tables according to APA guidelines
#' (6th edition).
#'
#' @param x Object to print, can be \code{matrix}, \code{data.frame}, or \code{list}. See details.
#' @param caption Character. Caption to be printed above the table.
#' @param note Character. Note to be printed below the table.
#' @param added_stub_head Character. Used as stub head (name of first column) if \code{row.names = TRUE}
#'    is passed to \code{\link[knitr]{kable}}; ignored if row names are omitted from the table.
#' @param col_spanners List. A named list of vectors of length 2 that contain the first and last column to
#'    span. The name of each list element containing the vector is used as grouping column name.
#' @param stub_indents List. A named list of vectors that contain indeces of the rows to indent. The name
#'    of each list element containing the vector is used as title for indented sections.
#' @param midrules Numeric. Vector of line numbers in table (not counting column headings) that should be
#'    followed by a horizontal rule; ignored in MS Word documents.
#' @param placement Character. Indicates whether table should be placed at the exact location (\code{h}),
#'    at the top (\code{t}), bottom (\code{b}), or on a separate page (\code{p}). Arguments can be combined
#'    to indicate order of preference (\code{htb}); ignored when \code{longtable = TRUE}, \code{landscape = TRUE},
#'    and in MS Word documents.
#' @param landscape Logical. If \code{TRUE} the table is printed in landscape format; ignored in MS Word
#'    documents.
#' @param small Logical. If \code{TRUE} the font size of the table content is reduced.
#' @param escape Logical. If \code{TRUE} special LaTeX characters, such as \code{\%} or \code{_}, in
#'    column names, row names, caption, note and table contents are escaped. Default is \code{TRUE} if
#'    target document format is PDF.
#' @param format.args List. A named list of arguments to be passed to \code{\link{printnum}} to format numeric values.
#' @param ... Further arguments to pass to \code{\link[knitr]{kable}}.
#'
#' @details
#'    When using \code{apa_table}, the type of the output (LaTeX or MS Word) is determined automatically
#'    by the rendered document type. If no rendering is in progress the output default is LaTeX.
#'    The chunk option of the enveloping chunk has to be set to \code{results = "asis"} to ensure the table
#'    is rendered, otherwise the table-generating markup is printed.
#'
#'    If \code{x} is a \code{list}, all list elements are merged by columns into a single table with
#'    the first column giving the names of the list elements elements.
#'
#'
#' @seealso \code{\link[knitr]{kable}}, \code{\link{printnum}}
#' @examples
#'
#' my_table <- t(apply(cars, 2, function(x) # Create data
#'   round(c(Mean = mean(x), SD = sd(x), Min = min(x), Max = max(x)), 2)
#' ))
#'
#' apa_table(
#'   my_table
#'   , align = c("l", rep("r", 3))
#'   , caption = "A summary table of the cars dataset."
#' )
#'
#' apa_table(
#'   cbind(my_table, my_table)
#'   , align = c("l", rep("r", 8))
#'   , caption = "A summary table of the cars dataset."
#'   , note = "This table was created using apa\\_table()"
#'   , added_stub_head = "Variables"
#'   , col_spanners = list(`Cars 1` = c(2, 5), `Cars 2` = c(6, 9))
#' )
#'
#' apa_table(
#'   list(`Cars 1` = my_table, `Cars 2` = my_table)
#'   , caption = "A summary table of the cars dataset."
#'   , added_stub_head = "Variables"
#' )
#' @export

apa_table <- function(
  x
  , caption = NULL
  , note = NULL
  , stub_indents = NULL
  , added_stub_head = NULL
  , col_spanners = NULL
  , midrules = NULL
  , placement = "tbp"
  , landscape = FALSE
  , small = FALSE
  , escape = NULL
  , format.args = NULL
  , ...
) {
  if(is.null(x)) stop("The parameter 'x' is NULL. Please provide a value for 'x'")
  if(!is.null(caption)) validate(caption, check_class = "character", check_length = 1)
  if(!is.null(note)) validate(note, check_class = "character", check_length = 1)
  if(!is.null(added_stub_head)) validate(added_stub_head, check_class = "character", check_length = 1)
  if(!is.null(stub_indents)) validate(stub_indents, check_class = "list")
  if(!is.null(escape)) validate(escape, check_class = "logical", check_length = 1)

  validate(placement, check_class = "character", check_length = 1)
  validate(landscape, check_class = "logical", check_length = 1)
  validate(small, check_class = "logical", check_length = 1)


  # Set defaults and rename ellipsis arguments
  ellipsis <- list(...)
  row_names <- if(is.null(ellipsis$row.names)) TRUE else ellipsis$row.names
  validate(row_names, "row.names", check_class = "logical", check_length = 1)
  if(is.null(ellipsis$digits) & is.null(format.args$digits)) {
    format.args$digits <- 2
  } else if(!is.null(ellipsis$digits)) {
    format.args$digits <- ellipsis$digits
  }

  if(is.null(escape)) {
    ellipsis$escape <- TRUE
  } else {
    ellipsis$escape <- escape
  }

  # List of tables?
  if(is.list(x) && !is.data.frame(x)) {
    # x <- lapply(x, as.data.frame, check.names = FALSE, fix.empty.names = FALSE, stringsAsFactors = FALSE)

    ## Assemble table
    if(row_names) {
      prep_table <- lapply(x, add_row_names, added_stub_head = added_stub_head)
    } else {
      prep_table <- x # lapply(x, data.frame, check.names = FALSE, fix.empty.names = FALSE, stringsAsFactors = FALSE)
    }

    ## Round numeric cells
    prep_table <- lapply(prep_table, format_cells, format.args)

    ## Assemble table
    # Old table merging by adding an additional column is depricated for the moment
#     prep_table <- merge_tables(
#       x
#       , empty_cells = ""
#       , row_names = row_names
#       , added_stub_head = added_stub_head
#     )

    prep_table <- do.call(rbind, prep_table)

  } else {
    # x <- as.data.frame(x, check.names = FALSE, fix.empty.names = FALSE, stringsAsFactors = FALSE)

    ## Assemble table
    if(row_names) {
      prep_table <- add_row_names(x, added_stub_head = added_stub_head)
    } else prep_table <- data.frame(x, check.names = FALSE, fix.empty.names = FALSE, stringsAsFactors = FALSE)

    ## Round numeric cells
    prep_table <- format_cells(prep_table, format.args)
  }

  # Escape special characters
  if(!is.null(ellipsis$escape) && ellipsis$escape) {
    prep_table <- as.data.frame(lapply(prep_table, escape_latex, spaces = TRUE), check.names = FALSE, fix.empty.names = FALSE, stringsAsFactors = FALSE)
    # prep_table <- default_label(prep_table)
    colnames(prep_table) <- escape_latex(colnames(prep_table))
    caption <- escape_latex(caption)
    note <- escape_latex(note)
  } else {
    prep_table <- as.data.frame(lapply(prep_table, function(x) gsub("([^\\\\]+)(%)", "\\1\\\\%", x)), check.names = FALSE, fix.empty.names = FALSE, stringsAsFactors = FALSE)
  }

  # Indent stubs
  ## Indent individual tables
  if(is.list(x) && !is.data.frame(x) && !is.null(names(x))) {
    list_indents <- lapply(x, function(x) 1:nrow(x))
    for(i in seq_along(list_indents)[-1]) list_indents[[i]] <- list_indents[[i]] + max(list_indents[[i - 1]])
    prep_table <- indent_stubs(prep_table, list_indents, "\\ \\ \\ ")
  }

  if(!is.null(stub_indents)) prep_table <- indent_stubs(prep_table, stub_indents, "\\ \\ \\ ")

  # Fix ellipsis for further use
  ellipsis$escape <- FALSE
  ellipsis$row.names <- FALSE

  # Pass to markup generating functions
  output_format <- knitr::opts_knit$get("rmarkdown.pandoc.to")

  if(!is.null(ellipsis[["format"]])) {
    output_format <- ellipsis[["format"]]
    ellipsis[["format"]] <- NULL
  } else {
    if(length(output_format) == 0 || output_format == "markdown") output_format <- "latex" # markdown_strict for render_appendix()
  }

  if(output_format == "latex") {
    if(!is.null(col_spanners)) {
      validate(col_spanners, check_class = "list")
      validate(unlist(col_spanners), "col_spanners", check_range = c(1, ncol(prep_table)))
    }

    do.call(
      function(...) apa_table.latex(
        x = prep_table
        , caption = caption
        , note = note
        , col_spanners = col_spanners
        , midrules = midrules
        , placement = placement
        , landscape = landscape
        , small = small
        , ...
      )
      , ellipsis
    )
  } else {
    do.call(
      function(...) apa_table.word(
        x = prep_table
        , caption = caption
        , note = note
        , ...
      )
      , ellipsis
    )
  }
}

#' @rdname apa_table
#' @export

apa_table.latex <- function(
  x
  , caption = NULL
  , note = NULL
  , col_spanners = NULL
  , midrules = NULL
  , placement = "tbp"
  , landscape = FALSE
  , small = FALSE
  , ...
) {
  apa_terms <- options()$papaja.terms

  # Parse ellipsis
  ellipsis <- list(...)
  ellipsis$booktabs <- TRUE
  longtable <- if(!is.null(ellipsis$longtable)) ellipsis$longtable else FALSE
  if(longtable || landscape) {
    table_env <-  "ThreePartTable"
    table_note_env <- "TableNotes"
  } else {
    table_env <- "threeparttable"
    table_note_env <- "tablenotes"
  }

  n_cols <- ncol(x)
  n_rows <- nrow(x)

  current_chunk <- knitr::opts_current$get("label")
  if(!is.null(current_chunk)) caption <- paste0("\\label{tab:", current_chunk, "}", caption)

  # Center title row
  # If x doesn't have variable labels, yet, create them...
  x <- default_label(x)
  # ...so that you can overwrite colnames(x) with (potentially) a mixture of labels and names
  colnames(x) <- paste0("\\multicolumn{1}{c}{", unlist(variable_label(x)), "}")
  colnames(x)[1] <- if(!is.na(variable_label(x)[[1]])) variable_label(x)[[1]] else ""

  res_table <- do.call(function(...) knitr::kable(x, format = "latex", ...), ellipsis)

  table_lines <- unlist(strsplit(res_table, "\n"))
  table_lines <- table_lines[!grepl("\\\\addlinespace", table_lines)] # Remove \\addlinespace

  # Add column spanners
  if(!is.null(col_spanners)) table_lines <- add_col_spanners(table_lines, col_spanners, n_cols)

  if((longtable || landscape) & !is.null(caption)) table_lines <- c(table_lines[1:2], paste0("\\caption{", caption, "}\\\\"), table_lines[-c(1:2)])

  table_content_boarders <- grep("\\\\midrule|\\\\bottomrule", table_lines)

  # Add extra space before note
  if(!is.null(note)) table_lines[table_content_boarders[2]] <- paste(table_lines[table_content_boarders[2]], "\\addlinespace", sep = "\n")

  # Add midrules
  if(!is.null(midrules)) {
    validate(midrules, check_class = "numeric", check_range = c(1, n_rows))

    table_lines[table_content_boarders[1] + midrules] <- paste(
      table_lines[table_content_boarders[1] + midrules]
      , "\\midrule"
    )
  }

  if(!is.null(note) & (longtable || landscape)) table_lines <- c(table_lines[-length(table_lines)], "\\insertTableNotes", table_lines[length(table_lines)])
  if(longtable || landscape) { # Makes caption as wide as table
    table_lines <- gsub("\\{tabular\\}", "{longtable}", table_lines)
    table_lines[grep("\\\\begin\\{longtable\\}", table_lines)] <- paste0(
      table_lines[grep("\\\\begin\\{longtable\\}", table_lines)]
      , "\\noalign{\\getlongtablewidth\\global\\LTcapwidth=\\longtablewidth}"
    )
  }
  res_table <- paste(table_lines, collapse = "\n")

  # Print table
  place_opt <- paste0("[", placement, "]")

  if(landscape) {
    # if(longtable) {
      cat("\\begin{lltable}")
    # } else {
      # cat("\\begin{ltable}")
    # }
    place_opt <- NULL
  }

  # if(longtable && placement != "h") cat("\\afterpage{\\clearpage") # Defer table to next clear page
  if(!landscape && !longtable) cat("\\begin{table}", place_opt, sep = "")
  if(!landscape) cat("\n\\begin{center}\n\\begin{", table_env, "}", sep = "")
  if(!is.null(caption) && !(longtable || landscape)) cat("\n\\caption{", caption, "}", sep = "")
  if(!is.null(note) && (longtable || landscape)) cat("\n\\begin{", table_note_env, "}[para]\n\\textit{", apa_terms$note, ".} ", note, "\n\\end{", table_note_env, "}", sep = "")
  if(small) cat("\n\\small{")

  cat(res_table)
  if(small) cat("\n}")
  if(!is.null(note) & !(longtable || landscape)) cat("\n\\begin{", table_note_env, "}[para]\n\\textit{", apa_terms$note, ".} ", note, "\n\\end{", table_note_env, "}", sep = "")
  if(!landscape) cat("\n\\end{", table_env, "}\n\\end{center}", sep = "")
  if(!landscape && !longtable) cat("\n\\end{table}")

  if(landscape) {
    # if(longtable) {
      cat("\n\\end{lltable}")
    # } else {
      # cat("\n\\end{ltable}")
    # }
  }
  # if(longtable && placement != "h") cat("\n}")
  cat("\n\n")
}


#' @rdname apa_table
#' @export

apa_table.word <- function(
  x
  , caption = NULL
  , note = NULL
  , ...
) {
  # Parse ellipsis
  ellipsis <- list(...)
  # If x doesn't have variable labels, yet, create them...
  x <- default_label(x)
  # ...so that you can overwrite colnames(x) with (potentially) a mixture of labels and names
  colnames(x) <- unlist(variable_label(x))
  colnames(x)[1] <- if(!is.na(variable_label(x)[[1]])) variable_label(x)[[1]] else ""

  res_table <- do.call(function(...) knitr::kable(x, format = "pandoc", ...), ellipsis)
  apa_terms <- options()$papaja.terms

  caption <- paste0("*", caption, "*")
  current_chunk <- knitr::opts_current$get("label")
  if(!is.null(current_chunk)) caption <- paste0("<caption>(\\#tab:", current_chunk, ")</caption>\n\n<caption>", caption, "</caption>\n\n")

  # Print table
  # cat("<caption>")
  # cat(apa_terms$table, ". ", sep = "")
  cat(caption)
  # cat("</caption>\n")

  print(res_table)

  if(!is.null(note)) {
    cat("\n")
    cat("<center>")
    cat("*", apa_terms$note, ".* ", note, sep = "")
    cat("</center>")
    cat("\n\n\n\n")
  }
}


#' Format numeric table cells
#'
#' Format all numeric cells of a table using \code{\link{printnum}}.
#' \emph{This function is not exported.}
#'
#' @param x data.frame or matrix.
#' @param format.args List. A named list of arguments to be passed to \code{\link{printnum}} to format numeric values.
#'
#' @keywords internal
#' @seealso \code{\link{printnum}}
#'
#' @examples
#' NULL

format_cells <- function(x, format.args = NULL) {
  numeric_columns <- sapply(x, is.numeric)
  if(any(numeric_columns)) {
    format.args$x <- x[, numeric_columns]
    x[, numeric_columns] <- do.call(printnum, format.args)
  }
  x
}


#' Add row names as first column
#'
#' Adds row names as the first column of the table and sets \code{row.name} attribute to \code{NULL}.
#' \emph{This function is not exported.}
#'
#' @param x data.frame or matrix.
#' @param added_stub_head Character. Used as stub head (name of first column).
#' @keywords internal
#' @seealso \code{\link{apa_table}}
#'
#' @examples
#' NULL

add_row_names <- function(x, added_stub_head) {
  if(!is.null(rownames(x)) && all(rownames(x) != 1:nrow(x))) {
    row_names <- rownames(x)
    rownames(x) <- NULL
    mod_table <- data.frame(row_names, x, check.names = FALSE, fix.empty.names = FALSE, stringsAsFactors = FALSE)

    if(!is.null(added_stub_head)) {
      colnames(mod_table) <- c(added_stub_head, colnames(x))
      if(is(mod_table, "apa_results_table")) variable_label(mod_table[, 1]) <- added_stub_head
    } else {
      colnames(mod_table) <- c("", colnames(x))
      if(is(mod_table, "apa_results_table")) variable_label(mod_table[, 1]) <- ""
    }
  } else mod_table <- data.frame(x, check.names = FALSE, fix.empty.names = FALSE, stringsAsFactors = FALSE)

  rownames(mod_table) <- NULL
  mod_table
}


#' Add stub indentation
#'
#' Indents stubs by line and adds section headings
#' \emph{This function is not exported.}
#'
#' @param x data.frame.
#' @param lines List. A named list of vectors of length 2 giving the first and second row to
#'    indent. Names of list elements will be used as titles for indented sections.
#' @param filler Character. Symbols used to indent stubs.
#' @keywords internal
#' @seealso \code{\link{apa_table}}
#'
#' @examples
#' NULL

indent_stubs <- function(x, lines, filler = "\ \ \ ") {
  x <- as.data.frame(lapply(x, as.character), check.names = FALSE, fix.empty.names = FALSE, stringsAsFactors = FALSE)

  # Add indentation
  for(i in seq_along(lines)) {
    x[lines[[i]], 1] <- paste0(filler, x[lines[[i]], 1])
  }

  section_titles <- lines[which(names(lines) != "")]
  section_titles <- sapply(section_titles, min)

  # Add section headings
  if(length(section_titles) > 0) {
    for(i in seq_along(section_titles)) {
      top <- if(section_titles[i] != 1) x[1:(section_titles[i] - 1 + (i-1)), ] else NULL
      bottom <- if(section_titles[i] != nrow(x)) x[(section_titles[i] + (i-1)):nrow(x), ] else x[nrow(x), ]
      x <- rbind.data.frame(top, c(names(section_titles[i]), rep("", ncol(x) - 1)), bottom)
    }
  }

  x
}


#' Add table headings to group columns
#'
#' Takes a named list of containing column numbers to group with a heading
#' \emph{This function is not exported.}
#'
#' @param table_lines Character. Vector of characters containing one line of a LaTeX table each.
#' @param col_spanners List. A named list containing the indices of the first and last columns to group, where the names are the headings.
#' @param n_cols Numeric. Number of columns of the table.
#' @keywords internal
#' @seealso \code{\link{apa_table}}
#'
#' @examples
#' NULL

add_col_spanners <- function(table_lines, col_spanners, n_cols) {

  # Grouping column names
  multicols <- sapply(
    seq_along(col_spanners)
    , function(i, names) {
      spanner_length <- diff(col_spanners[[i]])
      if(length(spanner_length) == 0) spanner_length <- 0
      paste0("\\multicolumn{", spanner_length + 1, "}{c}{", names[i], "}")
    }
    , names(col_spanners)
  )

  ## Calculate group distances
  multicol_spanners <- vapply(col_spanners, length, 1) > 1
  n_ampersands <- c()
  if(sum(multicol_spanners) > 1) {
    for(i in 2:length(col_spanners)) {
        n_ampersands <- c(n_ampersands, min(col_spanners[[i]]) - max(col_spanners[[i - 1]]))
    }
  }
  n_ampersands <- c(n_ampersands, 0)

  ## Add ampersands for empty columns
  leading_amps <- paste(rep(" &", min(unlist(col_spanners)) - 1), collapse = " ")
  trailing_amps <- if(n_cols - max(unlist(col_spanners)) > 0) {
    paste(rep(" &", n_cols - max(unlist(col_spanners))), collapse = " ")
  } else ""


  group_headings <- c()
  for(i in 1:(length(col_spanners))) {
    group_headings <- paste(group_headings, multicols[i], paste(rep("&", n_ampersands[i]), collapse = " "))
  }
  group_headings <- paste(leading_amps, group_headings, trailing_amps, "\\\\", sep = "")

  # Grouping midrules
  group_midrules <- sapply(
    seq_along(col_spanners)
    , function(i) {
      paste0("\\cmidrule(r){", min(col_spanners[[i]]), "-", max(col_spanners[[i]]), "}")
    }
  )
  group_midrules <- paste(group_midrules, collapse = " ")


  table_environment <- which(grepl("\\\\toprule", table_lines))

  table_lines <- c(
    table_lines[1:table_environment]
    , group_headings
    , group_midrules
    , table_lines[(table_environment + 1):length(table_lines)]
  )

  table_lines
}


#' Merge tables in list
#'
#' Takes a list of containing one or more \code{matrix} or \code{data.frame} and merges them into a single table.
#' \emph{This function is not exported and currently unused.}
#'
#' @param x List. A named list containing one or more \code{matrix} or \code{data.frame}.
#' @param empty_cells Character. String to place in empty cells; should be \code{""} if the target document is LaTeX and
#'    \code{"&nbsp;"} if the target document is Word.
#' @param row_names Logical. Vector of boolean values specifying whether to print column names for the corresponding list
#'    element.
#' @param added_stub_head Character. Vector of names for first unnamed columns. See \code{\link{apa_table}}.
#' @keywords internal
#' @seealso \code{\link{apa_table}}
#'
#' @examples
#' NULL

merge_tables <- function(x, empty_cells, row_names, added_stub_head) {

  table_names <- names(x)

  prep_table <- lapply(seq_along(x), function(i) {

    if(row_names[i]) {
      i_table <- add_row_names(x[[i]], added_stub_head = added_stub_head[(length(added_stub_head) == 2) + 1])
    } else if(any(row_names)) { # Add empty column if row names are added to any table
      i_table <- cbind("", i_table)
      colnames(i_table) <- c("", colnames(i_table))
    } else i_table <- x[[i]]

    # Merge with added column
    prep_table <- cbind(
      c(table_names[i], rep("", nrow(x[[i]])-1))
      , i_table
    )

    # Add colnames
    if(row_names[i] && !is.null(rownames(x[[i]])) && length(added_stub_head) < 2) {
      second_col <- ""
    } else second_col <- NULL
    if(is.null(added_stub_head)) {
      colnames(prep_table) <- c("", second_col, colnames(x[[i]]))
    } else {
      colnames(prep_table) <- c(added_stub_head, second_col, colnames(x[[i]]))
    }

    as.data.frame(prep_table, stringsAsFactors = FALSE)
  })

  prep_table
}
