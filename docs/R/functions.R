library(htmltools)

aside <- function(text) {
  return(tag("aside", list(text)))
}

center <- function(text) {
  return(tag("center", list(text)))
}

aside_center <- function(text) {
  return(aside(center(list(text))))
}

aside_center_b <- function(text) {
  return(aside(center(list(tag("b", text)))))
}

haiku <- function(one, two, three) {
  return(aside_center(list(
    em(one, HTML("&#8226;"), two, HTML("&#8226;"), three)
  )))
}

markdown_to_html <- function(text) {
  if (is.null(text)) { return(text) }
  return(HTML(markdown::renderMarkdown(text = text)))
}

make_icon <- function(icon) {
  return(tag("i", list(class = icon)))
}

make_icon_text <- function(icon, text) {
  return(HTML(paste0(make_icon(icon), " ", text)))
}

# Creates the html to make a button to an external link
icon_link <- function(icon = NULL, text = NULL, url = NULL) {
  if (!is.null(icon)) {
    text <- make_icon_text(icon, text)
  }
  return(a(href = url, text, class = "icon-link"))
}

doi <- function(doi) {
  url <- paste0('https://doi.org/', doi)
  return(paste0('DOI: ', a(href = url, doi)))
}

gscholar_stats <- function(url) {
  cites <- get_cites(url)
  return(paste(
    'Citations:', cites$citations, '|',
    'h-index:',   cites$hindex, '|',
    'i10-index:', cites$i10index
  ))
}

get_cites <- function(url) {
  html <- xml2::read_html(url)
  node <- rvest::html_nodes(html, xpath='//*[@id="gsc_rsb_st"]')
  cites_df <- rvest::html_table(node)[[1]]
  names(cites_df)[1] <- "category"
  cites_df$`Since 2016` <- NULL
  cites <- tidyr::spread(cites_df, category, All)
  names(cites) <- c('citations', 'hindex', 'i10index')
  return(cites)
}

# Functions for projects page: https://jhelvy.github.io/projects

make_posts_page <- function(posts) {
  categories <- get_post_categories(posts)
  posts <- unite_post_categories(posts, categories)
  posts_html <- make_posts_html(posts)
  cats_html <- make_cats_html(categories)
  return(
    div(class = "posts-container posts-with-sidebar posts-apply-limit l-screen-inset", 
        posts_html,
        cats_html
    ))
}

get_post_categories <- function(posts) {
  categories <- posts |> 
    select(-c("title", "src", "url", "description")) |> 
    pivot_longer(
      cols = everything(),
      names_to = "category",
      values_to = "count") |> 
    group_by(category) |> 
    summarise(count = sum(count)) |> 
    arrange(desc(count))
  return(categories)
}

unite_post_categories <- function(posts, categories) {
  posts <- posts |> 
    pivot_longer(
      names_to = "categories", 
      values_to = "val", 
      cols = categories$category) |> 
    mutate(val = ifelse(val == 1, categories, NA_character_)) |> 
    pivot_wider(
      names_from = categories, 
      values_from = val) |> 
    unite(
      -c('title', 'src', 'url', 'description'), 
      col = "categories", sep = ";", na.rm = T)
  return(posts)
}

make_posts_html <- function(posts) {
  posts_content <- list()
  for (i in seq_len(nrow(posts))) {
    posts_content[[i]] <- make_post_content(posts[i,])
  }
  return(div(class = "posts-list", posts_content))
}

make_post_content <- function(post) {
  post_cats <- strsplit(post$categories, ";")[[1]]
  post_tags <- get_post_tags(post_cats)
  return(a(
    href = post$url,
    class = "post-preview",
    HTML(
      paste0(
        '<script class="post-metadata" type="text/json">{"categories":[',
        paste0(paste0('"', post_cats, '"'), collapse = ","),
        ']}</script>'
      )
    ),
    div(class = "metadata", div(class = "publishedDate")),
    div(class = "thumbnail", img(src = post$src)),
    div(class = "description",
        h2(post$title),
        post_tags,
        p(post$description)
    )
  ))
}

get_post_tags <- function(post_cats) {
  cats <- list()
  for (i in seq_len(length(post_cats))) {
    cats[[i]] <- div(class = "dt-tag", post_cats[i])
  }
  return(div(class = "dt-tags", cats))
}

make_cats_html <- function(categories) {
  return(div(class = "posts-sidebar",
             div(class = "sidebar-section categories",
                 h3("Categories"),
                 make_cats_list(categories)
             )
  ))
}

make_cats_list <- function(categories) {
  cats_list <- list()
  for (i in seq_len(nrow(categories))) {
    cats_list[[i]] <- tags$li(
      a(
        href = paste0("#category:", categories$category[i]),
        categories$category[i]
      ),
      HTML(paste0(
        '<span class="category-count">(', 
        categories$count[i], ')</span>'
      ))
    )
  }
  return(tags$ul(cats_list))
}

create_footer <- function() {
  
  fill <- '#ededeb'
  height <- '14px'
  
  footer <- HTML(paste0(
    '© 2021 Tales Gomes [',
    fontawesome::fa('creative-commons', fill = fill, height = height),
    fontawesome::fa('creative-commons-by', fill = fill, height = height),
    fontawesome::fa('creative-commons-sa', fill = fill, height = height),
    '](https://creativecommons.org/licenses/by-sa/4.0/)\n',
    br(),
    fontawesome::fa('wrench', fill = fill, height = height), ' Feito com ',
    fontawesome::fa('heart', fill = fill, height = height), ', [',
    fontawesome::fa('code-branch', fill = fill, height = height),
    '](https://github.com/talesgomes27), e o pacote [',
    fontawesome::fa('r-project', fill = fill, height = height),
    '](https://cran.r-project.org/) ',
    '[distill](https://github.com/rstudio/distill) \n',
    br(),
    last_updated(), "\n\n",
    
    '<!-- Add function to open links to external links in new tab, from: -->',
    '<!-- https://yihui.name/en/2018/09/target-blank/ -->\n\n',
    '<script src="js/external-link.js"></script>'
  ))
  
  save_raw(footer, "_footer.html")
}



last_updated <- function() {
  return(span(
    paste0(
      'Ultima atualização em ',
      #format(Sys.Date(), format="%d de %B de %Y")
      format(Sys.Date(), format="%B de %Y")
    ),
    style = "font-size:0.8rem;")
  )
}

save_raw <- function(text, path) {
  fileConn <- file(path)
  writeLines(text, fileConn)
  close(fileConn)
}
