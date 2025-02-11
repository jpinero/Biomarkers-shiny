function(input, output, session) {

  observeEvent(input$header_title, {
    updateNavbarPage(inputId = "navbarPage", selected = "about")
  })
  
  observeEvent(input$reload1, {
    dt$Symbol <- NULL
    dt$DiseaseId <- NULL
    dt$dt_gds <- pool %>%
      tbl("gene_disease_summary") %>% 
      collect()
  })
  
  observeEvent(input$reload2, {
    dt$dt_gd <- NULL
    query <- "select gd.*, g.symbol, d.name
            from gene_disease as gd
            left join genes as g
            on gd.geneid = g.geneid
            left join diseases as d
            on gd.diseaseid = d.diseaseid"
    dt$dt_gd <- pool %>%
      dbGetQuery(query) %>%
      collect()
  })
  
  
  dt <- reactiveValues(dt_genes = NULL,
                       dt_diseases = NULL,
                       dt_studies = NULL,
                       dt_gds = NULL,
                       dt_gd = NULL,
                       dt_publications = NULL,
                       Symbol = NULL,
                       DiseaseId = NULL)
  
  observe({
    
    switch (req(input$navbarPage),
      "genes" = {
        dt$dt_genes <- pool %>%
        tbl("genes") %>% 
        collect() %>% 
          mutate(symbol = createLink_Symbol(geneid, symbol)) %>%
          rename( "Gene" = symbol, "type of gene" = type_of_gene,
                  "protein class" = PROTEIN_CLASS_NAMES,
                 "DPI" = dpi, "DSI" = dsi, "pLI"=pli,
                 "year initial" = year_initial, "year final" = year_final, 
               "Num. Clin.Trials" =  nclinicaltrials, 
               "Num. Diseases" = ndiseases, "Num. Pmids" = npmids)  %>% 
          select(Gene, description, `type of gene`, DSI, DPI, pLI,`protein class`,
                 `Num. Clin.Trials`, `Num. Diseases`, `Num. Pmids`,
                 `year initial`, `year final`
                 ) %>%  arrange(desc(`Num. Clin.Trials`) )
        },
      
      "diseases" = {
        dt$dt_diseases <- pool %>% 
          tbl("diseases") %>% 
          collect() %>% mutate(  name = createLink_Name(diseaseid, name)) %>%
        rename("Condition" = name, "Semantic Type" = sty, 
                               "Num. Biomarkers" = nbiomarkers, 
                               "year initial" = year_initial, "year final" = year_final, 
                               "Num. Clin.Trials" =  nclinicaltrials, 
                               "Num. Pmids" = npmids) %>%
        select(Condition, "Semantic Type",  "Num. Biomarkers" ,
               `Num. Clin.Trials`,   `Num. Pmids`,
               `year initial`, `year final`) %>%  arrange(desc(`Num. Clin.Trials`) )
      },
      
      "studies" = {
        dt$dt_studies <- pool %>% 
          tbl("studies") %>% 
          collect() %>% 
          rename(   "NCT ID" = nctid, "Brief Title" = brief_title, 
                    "Official Title" = official_title,  
                    "Num. GDAS" = ngdas, "Num. Genes" = ngenes, "Num. Diseases" = ndiseases,
                    "Num Pmids" = npmids, "Study Type" = study_type       )  %>% 
          select("NCT ID" , "Brief Title",  "Official Title", "Study Type", "Official Title", 
                 "Num. GDAS", "Num. Genes", "Num. Diseases", "Num Pmids") %>%  arrange(desc(`Num. GDAS`) )
        },
      
      "gene_disease_summary" = {
        dt$dt_gds <- pool %>%
          tbl("gene_disease_summary") %>% 
          collect() %>% 
          filter( if( !is.null(dt$Symbol) ) symbol == dt$Symbol else TRUE ) %>% 
          filter( if( !is.null(dt$DiseaseId) ) diseaseid == dt$DiseaseId else TRUE ) %>%
          select(-geneid, -diseaseid, -id) %>% 
          rename(            "Gene" = symbol, "Condition" = name,  
                 "year initial" = year_initial, "year final" = year_final, 
                 "Num. Clin.Trials" =  nclinicaltrials, 
                  "Num. Pmids" = npmids)  %>% 
          select(Gene, Condition, 
                 `Num. Clin.Trials`,   `Num. Pmids`,
                 `year initial`, `year final`
          )%>%  arrange(desc(`Num. Clin.Trials`) )

        }, 
      
      "gene_disease" = {
        query <- "select gd.*, g.symbol, d.name
            from gene_disease as gd
            left join genes as g
            on gd.geneid = g.geneid
            left join diseases as d
            on gd.diseaseid = d.diseaseid"
        dt$dt_gd <- pool %>%
          dbGetQuery(query) %>%
          collect() %>% 
          filter( if( !is.null(dt$Symbol) ) symbol == dt$Symbol else TRUE ) %>% 
          filter( if( !is.null(dt$DiseaseId) ) diseaseid == dt$DiseaseId else TRUE )
      },
      
      "publications" = {
        query <- "select p.*, g.symbol, d.name
            from publications as p
            left join genes as g
            on p.geneid = g.geneid
            left join diseases as d
            on p.mesh = d.diseaseid"
        dt$dt_publications <- pool %>% 
          dbGetQuery(query) %>% 
          collect()
      }
    )
  })

  
  output$genes <- DT::renderDataTable({
    dt$dt_genes %>% 
      mutate(`Num. Clin.Trials` = createLink_Button(`Num. Clin.Trials`))
    }, 
    filter = "top",
    options = list(scrollX = TRUE, dom = 'ltipr', pageLength = 10),
    rownames = FALSE,
    escape = FALSE,
    selection = list(mode = 'single', target = 'cell'))
  
  
  geneProxy <- dataTableProxy('genes')
  
  observeEvent(input$genes_cells_selected, {
    value <- input$genes_cells_selected
    geneProxy %>%  selectCells(NULL)
    if(length(value > 1)) {
      col <- value[,2]
      if(col == "0"){
        value[,2] <- value[,2] + 1
        ## very awful but i refuse to convert tibble to data.frame just for this
        dt$Symbol <- dt$dt_genes[value[,1], value[,2], drop = TRUE]
        updateNavbarPage(inputId = "navbarPage", selected = "gene_disease_summary")
      }
    }
  })
  
  output$diseases <- DT::renderDataTable({
    dt$dt_diseases %>% 
      mutate(`Num. Clin.Trials` = createLink_Button(`Num. Clin.Trials`))
  },
  filter = "top",
  selection = list(mode = 'single', target = 'cell'),
  options = list(dom = 'ltipr'),
  rownames = FALSE,
  escape = FALSE)
  
  diseaseProxy <- dataTableProxy('diseases')
  
  observeEvent(input$diseases_cells_selected, {
    value <- input$diseases_cells_selected
    diseaseProxy %>% selectCells(NULL)
    if(length(value > 1)) {
      col <- value[,2]
      if(col == "0"){
        value[,2] <- value[,2] + 1
        dt$DiseaseId <- dt$dt_diseases[value[,1], value[,2], drop = TRUE]
        updateNavbarPage(inputId = "navbarPage", selected = "gene_disease_summary")
      }
    }
  })
  
  output$studies <- DT::renderDataTable({
    dt$dt_studies %>%
      mutate(`NCT ID` = createLink_NCIT(`NCT ID`))
  }, filter = "top",
  options = list(scrollX = TRUE, dom = 'ltipr', pageLength = 10),
  rownames = FALSE,
  escape = FALSE,
  selection = list(mode = 'single', target = 'cell'))


  output$gene_disease_summary <- DT::renderDataTable({
    dt$dt_gds %>%
      mutate(`Num. Clin.Trials` = createLink_Button(`Num. Clin.Trials`))
  }, filter = "top",
  options = list(dom = 'ltipr'),
  selection = list(mode = 'single', target = 'cell'),
  escape = FALSE,
  rownames = FALSE)
  
  observeEvent(input$gene_disease_summary_cells_selected, {
    value <- input$gene_disease_summary_cells_selected
    if(length(value)>1) {
      col <- value[,2]
      if(col == "4"){
        rows <- value[,1]
        cols <- value[,2] + 1
        dt$Symbol <- dt$dt_gds[rows,3, drop = TRUE]
        dt$DiseaseId <- dt$dt_gds[rows, 2, drop = TRUE]
        updateNavbarPage(inputId = "navbarPage", selected = "gene_disease")
      }
    }
  })
  
  output$gene_disease <- DT::renderDataTable({
    dt$dt_gd %>%
      mutate(symbol = createLink_Symbol(geneid, symbol),
             nctid =   createLink_NCIT(nctid),
           #  pmid =   createLink_PMID(pmid),
             name = createLink_Name(diseaseid, name)) %>%
      select(-id, -sentenceHtml, -geneid, -diseaseid) %>%
      relocate(symbol, .after=nctid) %>%
      relocate(name, .after=symbol) %>% 
      rename("Gene" = symbol, "Condition" = name, 
             "NCT ID" = nctid, "Measurement" = sentence, 
             "Num. Pmids" = npmids,
             "Biomarker Type" = bmtype ) %>%  arrange(desc(`Num. Pmids`) )
      
  },
  escape = FALSE,
  filter = "top",
  options = list(dom = 'ltipr'),
  rownames = FALSE) 
  
  output$publications <- DT::renderDataTable({
    dt$dt_publications %>%
      mutate(symbol = createLink_Symbol(geneid, symbol),
             nctid =   createLink_NCIT(nctid),
              pmid =   createLink_PMID(pmid),
             name = createLink_Name(mesh, name)) %>%
      select(-id, -geneid, -mesh) %>%
      rename("Gene" = symbol, "Condition" = name, 
             "NCT ID" = nctid ) %>%  arrange(desc(year) )
    
  }, filter = "top",
  options = list(dom = 'ltipr'),
  selection = list(mode = 'single', target = 'cell'),
  escape = FALSE,
  rownames = FALSE)  
}