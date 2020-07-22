# Load our dependencies
library(pacman)
p_load(rmarkdown, knitr, rjson)

process_file_name = function(file_name) {
  # String split to get the name of the folder, the name of the file,
  # and the pre-extension name of the file ("base_name")
  folder_chunks = strsplit(file_name, "/")
  stripped_file_name = folder_chunks[[1]][length(folder_chunks[[1]])]
  base_name = substr(stripped_file_name, 
                     1, (nchar(stripped_file_name)-4))
  folder_name = paste0(
    paste(folder_chunks[[1]][1:(length(folder_chunks[[1]])-1)],
          collapse = "/"),
    "/")

  # Check if we have a current HTML version
  html_version = paste0(folder_name, base_name, ".html")
  json_metadata = paste0(folder_name, base_name, ".json")
  extra_outputs = paste0(folder_name, base_name, "_files")
  if(file.exists(json_metadata)) {
    needs_recompile = read_expiry_date(json_metadata)
  } else {
    needs_recompile = TRUE
  }
  
  compiled_exists = file.exists(html_version) && 
    file.exists(json_metadata) && file.exists(extra_outputs)

  # Conditions where we need an update:
  # - Compiled files do not exist
  # - Compiled files do exist and the Rmd file has changed since the 
  #   HTML version has changed
  # - Compiled files do exist, but the JSON tells us it's time to recompile
  need_update = ifelse(
    compiled_exists,
    ifelse(
      file.mtime(file_name) > file.mtime(html_version),
      TRUE,
      needs_recompile
    ),
    TRUE)

  # Maybe we don't need an update, but we want one because it was requested by 
  # the yaml
  yaml_metadata_list = rmarkdown::yaml_front_matter(file_name)
  if(!is.null(yaml_metadata_list$update_until) && 
     yaml_metadata_list$update_until > Sys.Date()) {
    want_update = 1
    cat("File is cached, but updated data requested... \n")
  } else {
    want_update = 0
  }

  # Do the update if necessary
  if(need_update || want_update) {
    cat("\tRendering Rmd to HTML... \n")
    render_file(file_name, folder_name)
    cat("\tWriting JSON metadata... \n")
    parse_front_matter(file_name, folder_name, base_name)
    clean_superfluous_libraries(folder_name, base_name)
  } else {
    cat("\tFile not modified, keeping cached version.\n")
  }

}

render_file = function(file_name, folder) {
  # Override default output options to use our template
  rmarkdown::render(input = file_name,
                    output_format = "html_document",
                    output_options = list(
                      template = "../../output_template/template_stub.html",
                      self_contained = FALSE
                    ),
                    output_dir = folder,
                    clean = TRUE,
                    quiet = TRUE)
  
}

clean_superfluous_libraries = function(folder_name, base_name) {
  # RMarkdown generates JS files for its dependencies, we don't need
  # them really.
  file_chunk = paste0(folder_name, base_name, "_files/")
  unlink(paste0(file_chunk, "bootstrap-*"), recursive = TRUE)
  unlink(paste0(file_chunk, "jquery-*"), recursive = TRUE)
  unlink(paste0(file_chunk, "navigation-*"), recursive = TRUE)
}

parse_front_matter = function(file_name, folder_name, base_name) {
  # Write a JSON 
  yaml_metadata_list = rmarkdown::yaml_front_matter(file_name)
  
  # 
  if(is.null(yaml_metadata_list$tag)) {
    cat("\tWARNING: No tags included in article metadata.\n")
  }
  if(is.null(yaml_metadata_list$title)) {
    cat("\tWARNING: No title included in article metadata,",
        "defaulting to \"", base_name, "\"\n")
    yaml_metadata_list$title = base_name
  }
  if(is.null(yaml_metadata_list$author)) {
    cat("\tWARNING: No author included in article metadata,",
        "defaulting to \"Voteview Team\"\n")
    yaml_metadata_list$author = "Voteview Team"
  }
  if(is.null(yaml_metadata_list$original_date)) {
    cat("\tWARNING: No original date in article metadata,",
        "defaulting to", format(Sys.Date(), "%Y-%m-%d"), "\n")
    yaml_metadata_list$original_date = format(Sys.Date(), "%Y-%m-%d")
  }
  if(is.null(yaml_metadata_list$cadence_update)) {
    yaml_metadata_list$update_delta = 7
  }
  update_date = format(Sys.Date() + yaml_metadata_list$update_delta, "%Y-%m-%d")
  
  json_output_list = list(
    title = yaml_metadata_list$title,
    author = yaml_metadata_list$author,
    description = yaml_metadata_list$description,
    original_date = yaml_metadata_list$original_date,
    date_modified = as.numeric(Sys.time()),
    recompile_date = update_date,
    tags = yaml_metadata_list$tags
  )
  
  write(rjson::toJSON(json_output_list), 
        paste0(folder_name, base_name, ".json"))
}

read_expiry_date = function(filename) {
  json_matter = fromJSON(file = filename)
  if(!"recompile_date" %in% names(json_matter)) { return(TRUE) }
     
  Sys.Date() > json_matter[["recompile_date"]]
}

core_loop = function() {
  # Process these
  rmd_process_list = list.files(".", ".Rmd$", recursive = TRUE)
  
  # Loop through the files we wish to process
  i = 1
  for(file_name in rmd_process_list) {
    cat(paste0("Processing file ", i, "/", 
               length(rmd_process_list), ": ", 
               file_name, "\n"))
    tryCatch({
      process_file_name(file_name)
    }, error = function(e) {
      print(e)
      cat("Error working on this file.\n")
    })
    i = i + 1
  } 
  cat("Job complete.\n")
}

core_loop()
