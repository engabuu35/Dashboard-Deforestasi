library(shiny)
library(ggplot2)
library(dplyr)
library(leaflet)
library(sf)
library(scales)
library(plotly)
library(tidyr)


shinyServer(function(input, output, session) {
  
  clicked_province <- reactiveVal("ALL")
  
  # Reset provinsi saat tab berubah
  observeEvent(input$tabs, {
    updateSelectInput(session, "prov", selected = "ALL")
    clicked_province("ALL")
  })
  
  # Klik peta -> update provinsi
  observeEvent(input$treeMap_shape_click, {
    click <- input$treeMap_shape_click
    if (!is.null(click$id)) {
      clicked_province(click$id)
      updateSelectInput(session, "prov", selected = click$id)
    }
  })
  
  # Dropdown berubah -> update reaktif klik
  observeEvent(input$prov, {
    clicked_province(input$prov)
  })
  
  # 1) Filter data berdasarkan dropdown provinsi
  filtered_data <- reactive({
    if (input$prov == "ALL") data else data %>% filter(Provinsi == input$prov)
  })
  
  # 2) Driver Utama (semua tahun)
  output$main_driver <- renderValueBox({
    df <- filtered_data()
    if (nrow(df) == 0) {
      return(valueBox("N/A", "Penyebab Utama Kehilangan Tutupan Pohon", icon = icon("tree"), color = "olive"))
    }
    top_drv <- df %>%
      group_by(Driver) %>%
      summarise(total_loss = sum(Tree_cover_loss, na.rm = TRUE)) %>%
      arrange(desc(total_loss)) %>%
      slice(1) %>%
      pull(Driver)
    
    valueBox(
      value    = top_drv,
      subtitle = "Penyebab Utama Kehilangan Tutupan Pohon",
      icon     = icon("tree"),
      color    = "olive"
    )
  })
  
  # == 3. Rata-rata kehilangan / tahun ===============================================
  output$avg_loss <- renderValueBox({
    df <- filtered_data()
    if (nrow(df) == 0) {
      return(valueBox("0 ha", "Rata-rata Kehilangan / Tahun", icon = icon("chart-line"), color = "olive"))
    }
    avg_l <- df %>%
      group_by(Tahun) %>%
      summarise(total = sum(Tree_cover_loss, na.rm = TRUE)) %>%
      summarise(avg = mean(total, na.rm = TRUE)) %>%
      pull(avg)
    
    valueBox(
      value = paste0(format(round(avg_l, 0), big.mark = ".", decimal.mark = ","), " ha"),
      subtitle = "Rata-rata Kehilangan Tutupan Pohon / Tahun",
      icon     = icon("chart-line"),
      color    = "olive"
    )
  })
  
  # == 4. Tahun kehilangan tertinggi =================================================
  output$max_loss_year <- renderValueBox({
    df <- filtered_data()
    if (nrow(df) == 0) {
      return(valueBox("N/A", "Tahun Kehilangan Terbesar", icon = icon("calendar-alt"), color = "olive"))
    }
    yr <- df %>%
      group_by(Tahun) %>%
      summarise(total = sum(Tree_cover_loss, na.rm = TRUE)) %>%
      slice_max(total) %>%
      pull(Tahun)
    
    valueBox(
      value    = yr,
      subtitle = "Tahun Kehilangan Tutupan Pohon Terbesar",
      icon     = icon("calendar-alt"),
      color    = "olive"
    )
  })
  
  # == 5. Line chart total loss per tahun ==========================================
  output$treeLossPlot <- renderPlotly({
    df <- filtered_data()
    if (nrow(df) == 0) {
      return(
        ggplot() + 
          annotate("text", x = 0.5, y = 0.5, label = "Tidak ada data", size = 6) + 
          theme_void()
      )
    }
    
    # 1) Driver pilihan
    df_driver <- df %>% 
      filter(Driver %in% c("Wildfire", "Permanent agriculture", "Logging")) %>% 
      group_by(Tahun, Driver) %>% 
      summarise(total = sum(Tree_cover_loss, na.rm = TRUE), .groups = "drop")
    
    # 2) Total semua driver
    df_total <- df %>%
      group_by(Tahun) %>%
      summarise(total = sum(Tree_cover_loss, na.rm = TRUE), .groups = "drop") %>%
      mutate(Driver = "Total")
    
    # 3) Gabungkan
    df_plot <- bind_rows(df_driver, df_total)
    
    p <- ggplot(df_plot, aes(x = Tahun, y = total, color = Driver, group = Driver, text = paste("Tahun:", Tahun,
                                                                                                "<br>Total:", format(round(total, 0), big.mark = "."),
                                                                                                "<br>Driver:", Driver))) +
      geom_line(size = 1) +
      geom_point(size = 2) +
      labs(
        x = "Tahun",
        y = "Kehilangan (ha)",   # ← label Y diganti
        color = "Driver"
      ) +
      scale_x_continuous(breaks = unique(df_plot$Tahun)) +
      scale_y_continuous(labels = scales::comma) +  # ← hilangkan notasi ilmiah
      scale_color_manual(values = c(
        "Wildfire"              = "#e53935",
        "Permanent agriculture" = "#fb8c00",
        "Logging"               = "#6d4c41",
        "Total"                 = "#2e7d32"
      )) +
      theme_minimal(base_size = 10) +
      theme(legend.position = "bottom")
    
    ggplotly(p, tooltip = "text")%>%
      layout(
        legend = list(
          orientation = "h",     # horizontal
          x = 0.5,
          xanchor = "center",
          y = -0.3,              # naik-turun (bisa disesuaikan)
          font = list(size = 10) #
        ),
        margin = list(l = 50, r = 30, b = 80, t = 30),  # tambah bawah (b) supaya ada ruang
        xaxis = list(
          tickangle = -45,  # miringkan label tahun
          tickfont = list(size = 10)
        ),
        yaxis = list(
          tickfont = list(size = 10)
        )
      )
  })
  
  # Interpretasi Line Chart
  output$interpretasi_linechart <- renderUI({
    prov <- input$prov
    
    data_prov <- if (prov == "ALL") data else data[data$Provinsi == prov, ]
    
    # Total loss per tahun
    total_by_year <- data_prov %>%
      group_by(Tahun) %>%
      summarise(loss = sum(Tree_cover_loss), .groups = "drop")
    
    tahun_puncak <- total_by_year %>% filter(loss == max(loss)) %>% pull(Tahun)
    
    # Penyebab dominan secara keseluruhan
    drivers <- c("Wildfire", "Logging", "Agriculture")  # Sesuaikan dengan kolommu
    driver_summary <- data_prov %>%
      group_by(Driver) %>%
      summarise(total = sum(Tree_cover_loss), avg = mean(Tree_cover_loss), .groups = "drop") %>%
      arrange(desc(total))
    
    penyebab_utama <- driver_summary$Driver[1]
    rata2_kontribusi <- round(100 * driver_summary$total[1] / sum(driver_summary$total), 1)
    
    # Penyebab tertinggi di tahun puncak
    penyebab_puncak <- data_prov %>%
      filter(Tahun == tahun_puncak) %>%
      group_by(Driver) %>%
      summarise(total = sum(Tree_cover_loss), .groups = "drop") %>%
      arrange(desc(total)) %>%
      slice(1) %>%
      pull(Driver)
    
    # Fungsi bantu tren
    cari_tren <- function(df, driver) {
      df_driver <- df %>% filter(Driver == driver) %>%
        group_by(Tahun) %>%
        summarise(total = sum(Tree_cover_loss), .groups = "drop")
      
      tahun_max <- df_driver$Tahun[which.max(df_driver$total)]
      
      if (nrow(df_driver) < 2) return(c("tidak tersedia", tahun_max, "-"))
      
      selisih <- tail(df_driver$total, 1) - head(df_driver$total, 1)
      tren <- ifelse(selisih > 0, "meningkat", ifelse(selisih < 0, "menurun", "stabil"))
      return(c("berfluktuasi", tahun_max, paste("kemudian", tren)))
    }
    
    wf_tren <- cari_tren(data_prov, "Wildfire")
    lg_tren <- cari_tren(data_prov, "Logging")
    ag_tren <- cari_tren(data_prov, "Permanent agriculture")
    
    total_tren <- ifelse(tail(total_by_year$loss, 1) > head(total_by_year$loss, 1), "meningkat",
                         ifelse(tail(total_by_year$loss, 1) < head(total_by_year$loss, 1), "menurun", "stabil"))
    
    HTML(paste0(
      "<div style='font-size:12px;'>",
      "<b>Provinsi:</b> ", prov, " (2015–2024)<br><br>",
      "<b>Penyebab dominan:</b> ", penyebab_utama, " (", rata2_kontribusi, "% per tahun)<br>",
      "<b>Puncak kehilangan:</b> Tahun ", tahun_puncak, ", terutama akibat ", penyebab_puncak, ".<br>",
      "<b>Tren Wildfire:</b> ", wf_tren[1], " — tertinggi pada ", wf_tren[2], ", lalu ", wf_tren[3], ".<br>",
      "<b>Tren Logging:</b> ", lg_tren[1], " — tertinggi pada ", lg_tren[2], ", lalu ", lg_tren[3], ".<br>",
      "<b>Tren Permanent Agriculture:</b> ", ag_tren[1], " — tertinggi pada ", ag_tren[2], ", lalu ", ag_tren[3], ".<br>",
      "<b>Total kehilangan:</b> cenderung ", total_tren, " selama periode 2015–2024."
    ))
  })
  
  # == 6. Pie chart driver loss (tahun terbaru) ===================================
  output$driverLossPie <- renderPlotly({
    df <- filtered_data()
    if (input$tahun != "ALL") {
      df <- df %>% filter(Tahun == as.integer(input$tahun))
    }
    if (nrow(df) == 0) {
      return(plotly_empty() %>% layout(title = "Tidak ada data"))
    }
    
    pie_df <- df %>%
      group_by(Driver) %>%
      summarise(val = sum(Tree_cover_loss, na.rm = TRUE)) %>%
      filter(val > 0) %>%
      mutate(
        val_fmt = format(round(val), big.mark = ".", decimal.mark = ","),  # 
        percent_fmt = paste0(format(round(100 * val / sum(val), 2), decimal.mark = ","), "%")
      )
    
    plot_ly(
      pie_df,
      labels = ~Driver,
      values = ~val,
      type   = "pie",
      text           = ~val_fmt,              # ← disimpan di text
      customdata     = ~percent_fmt,
      textinfo       = "none",                # tak ada label di irisan
      hoverinfo      = "label+percent+text",  # bawaan plotly + nilai text
      hovertemplate  = "%{label}<br>Jumlah: %{text} ha<br>Persen: %{customdata}<extra></extra>",
      marker = list(line = list(color = "#FFFFFF", width = 1))
    ) %>% 
      layout(
        showlegend = TRUE,
        legend = list(
          y = 0.5,          # posisi tengah secara vertikal
          yanchor = "middle" # titik tengah vertikal
        ),
        margin = list(l = 20, r = 20, b = 20, t = 20)
      )%>% 
      layout(
        showlegend = TRUE,
        legend = list(
          y = 0.5,          # posisi tengah secara vertikal
          yanchor = "middle" # titik tengah vertikal
        ),
        margin = list(l = 20, r = 20, b = 20, t = 20)
      )
  })
  
  # Interpretasi pie chart
  output$interpretasi_piechart <- renderUI({
    # Filter sesuai input user
    df <- data
    if (input$prov != "ALL") {
      df <- df[df$Provinsi == input$prov, ]
    }
    if (input$tahun != "ALL") {
      df <- df[df$Tahun == input$tahun, ]
    }
    
    # Hitung total kehilangan dan proporsi tiap driver
    df_summary <- df %>%
      group_by(Driver) %>%
      summarise(Kehilangan = sum(Tree_cover_loss, na.rm = TRUE)) %>%
      arrange(desc(Kehilangan))
    
    total_loss <- sum(df_summary$Kehilangan, na.rm = TRUE)
    main_driver <- df_summary$Driver[1]
    main_value <- df_summary$Kehilangan[1]
    
    if (total_loss == 0 || is.na(total_loss)) {
      HTML("<p style='font-size:13px;'>Tidak ada data kehilangan tutupan pohon untuk kombinasi provinsi dan tahun yang dipilih.</p>")
    } else {
      prop_main <- round((main_value / total_loss) * 100, 1)
      HTML(glue::glue("<p style='font-size:12px;'>
      Pada provinsi <b>{input$prov}</b> dan tahun <b>{input$tahun}</b>, 
      penyebab utama kehilangan tutupan pohon adalah <b>{main_driver}</b> 
      dengan kontribusi sekitar <b>{prop_main}%</b> dari total kehilangan seluas 
      <b>{scales::comma(round(total_loss))} ha</b>.
    </p>"))
    }
  })
  
  
  # == 7. Tampilkan peta interaktif  ===============================================
  output$treeMap <- renderLeaflet({
    
    data_tahun <- if (input$tahun_peta == "ALL") data else
      data %>% filter(Tahun == as.integer(input$tahun_peta))
    
    loss_by_prov <- data_tahun %>%
      group_by(Provinsi) %>%
      summarise(total_loss = sum(Tree_cover_loss, na.rm = TRUE))
    
    kalimantan_filtered <- kalimantan_geo %>%
      select(-total_loss) %>%
      left_join(loss_by_prov, by = "Provinsi")
    
    pal <- colorNumeric(
      palette = "YlOrRd",
      domain = kalimantan_filtered$total_loss,
      na.color = "transparent"
    )
    
    leaflet(kalimantan_filtered) %>%
      addProviderTiles("CartoDB.Positron") %>%
      addPolygons(
        fillColor = ~pal(total_loss),
        weight = 1,
        opacity = 1,
        color = "white",
        fillOpacity = 0.7,
        layerId = ~Provinsi,
        highlightOptions = highlightOptions(
          color = "black", weight = 2, bringToFront = TRUE
        ),
        label = ~paste0(
          "<strong>", Provinsi, "</strong><br>",
          "Total Loss: ", format(round(total_loss, 0), big.mark = ".", decimal.mark = ","), " ha"
        ) %>% lapply(htmltools::HTML)
      ) %>%
      addLegend(
        pal      = pal,
        values   = ~total_loss,
        opacity  = 0.7,
        title    = "Total Kehilangan Tutupan Pohon",
        position = "bottomright",
        labFormat = labelFormat(
          big.mark = ".", suffix = " ha"
        )
      )
  })
  
  # Interpretasi Peta Penyebab Deforestasi
  output$interpretasi_peta <- renderUI({
    selected_year <- input$tahun_peta
    
    if (selected_year == "ALL") {
      data_all <- data %>%
        group_by(Provinsi) %>%
        summarise(loss = sum(Tree_cover_loss, na.rm = TRUE), .groups = "drop") %>%
        arrange(desc(loss))
      
      prov_max <- data_all$Provinsi[1]
      loss_max <- format(round(data_all$loss[1], 1), big.mark = ".")
      prov_min <- data_all$Provinsi[nrow(data_all)]
      loss_min <- format(round(data_all$loss[nrow(data_all)], 1), big.mark = ".")
      avg_loss <- format(round(mean(data_all$loss), 1), big.mark = ".")
      
      return(HTML(paste0(
        "<p>Selama periode <b>2015–2025</b>, provinsi dengan kehilangan tutupan pohon tertinggi adalah <b>", prov_max, "</b> (", loss_max, " ha), ",
        "dan terendah adalah <b>", prov_min, "</b> (", loss_min, " ha).</p>",
        "<p>Rata-rata kehilangan per provinsi dalam periode ini adalah sekitar <b>", avg_loss, " ha</b>.</p>"
      )))
    }
    
    data_tahun <- data %>%
      filter(Tahun == selected_year) %>%
      group_by(Provinsi) %>%
      summarise(loss = sum(Tree_cover_loss), .groups = "drop") %>%
      arrange(desc(loss))
    
    if (nrow(data_tahun) == 0) {
      return(HTML("<p>Data tidak tersedia untuk tahun yang dipilih.</p>"))
    }
    
    prov_max <- data_tahun$Provinsi[1]
    loss_max <- format(round(data_tahun$loss[1], 1), big.mark = ".")
    prov_min <- data_tahun$Provinsi[nrow(data_tahun)]
    loss_min <- format(round(data_tahun$loss[nrow(data_tahun)], 1), big.mark = ".")
    avg_loss <- format(round(mean(data_tahun$loss), 1), big.mark = ".")
    
    HTML(paste0(
      "<p>Pada tahun <b>", selected_year, "</b>, provinsi dengan kehilangan tutupan pohon tertinggi adalah <b>", prov_max, "</b> (", loss_max, " ha), ",
      "sedangkan yang terendah adalah <b>", prov_min, "</b> (", loss_min, " ha).</p>",
      "<p>Rata-rata kehilangan tutupan pohon di seluruh provinsi Kalimantan pada tahun ini adalah sekitar <b>", avg_loss, " ha</b>.</p>"
    ))
  })

  output$carbonMap <- renderLeaflet({
    data_tahun <- if (input$tahun_peta_karbon == "ALL") data else
      data %>% filter(Tahun == as.integer(input$tahun_peta_karbon))
    
    carbon_by_prov <- data_tahun %>%
      group_by(Provinsi) %>%
      summarise(total_carbon = sum(Gross_carbon, na.rm = TRUE))
    
    kalimantan_filtered <- kalimantan_geo %>%
      select(-total_loss) %>%
      left_join(carbon_by_prov, by = "Provinsi")
    
    pal <- colorNumeric(
      palette = c("#d1d1d1", "#9a9a9a", "#6b6b5b", "#3c3c3c", "#111100"),
      domain = kalimantan_filtered$total_carbon,
      na.color = "transparent"
    )
    
    leaflet(kalimantan_filtered) %>%
      addProviderTiles("CartoDB.Positron") %>%
      addPolygons(
        fillColor = ~pal(total_carbon),
        weight = 1,
        opacity = 1,
        color = "white",
        fillOpacity = 0.7,
        layerId = ~Provinsi,
        highlightOptions = highlightOptions(
          color = "black", weight = 2, bringToFront = TRUE
        ),
        label = ~paste0(
          "<strong>", Provinsi, "</strong><br>",
          "Total Emisi: ", format(round(total_carbon, 0), big.mark = ".", decimal.mark = ","), " ton"
        ) %>% lapply(htmltools::HTML)
      ) %>%
      addLegend(
        pal      = pal,
        values   = ~total_carbon,
        opacity  = 0.7,
        title    = "Total Emisi Karbon Bruto",
        position = "bottomright",
        labFormat = labelFormat(
          big.mark = ".", suffix = " ton"
        )
      )
    
  })
  
  output$interpretasi_peta2 <- renderUI({
    selected_year <- input$tahun_peta_karbon
    
    if (selected_year == "ALL") {
      data_all <- data %>%
        group_by(Provinsi) %>%
        summarise(carbon = sum(Gross_carbon, na.rm = TRUE), .groups = "drop") %>%
        arrange(desc(carbon))
      
      prov_max <- data_all$Provinsi[1]
      carbon_max <- format(round(data_all$carbon[1], 1), big.mark = ".")
      prov_min <- data_all$Provinsi[nrow(data_all)]
      carbon_min <- format(round(data_all$carbon[nrow(data_all)], 1), big.mark = ".")
      avg_carbon <- format(round(mean(data_all$carbon), 1), big.mark = ".")
      
      return(HTML(paste0(
        "<p>Selama periode <b>2015–2025</b>, provinsi dengan emisi karbon bruto tertinggi adalah <b>", prov_max, "</b> (", carbon_max, " ton), ",
        "dan terendah adalah <b>", prov_min, "</b> (", carbon_min, " ton).</p>",
        "<p>Rata-rata emisi karbon bruto per provinsi dalam periode ini adalah sekitar <b>", avg_carbon, " ton</b>.</p>"
      )))
    }
    
    data_tahun <- data %>%
      filter(Tahun == selected_year) %>%
      group_by(Provinsi) %>%
      summarise(carbon = sum(Gross_carbon, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(carbon))
    
    if (nrow(data_tahun) == 0) {
      return(HTML("<p>Data tidak tersedia untuk tahun yang dipilih.</p>"))
    }
    
    prov_max <- data_tahun$Provinsi[1]
    carbon_max <- format(round(data_tahun$carbon[1], 1), big.mark = ".")
    prov_min <- data_tahun$Provinsi[nrow(data_tahun)]
    carbon_min <- format(round(data_tahun$carbon[nrow(data_tahun)], 1), big.mark = ".")
    avg_carbon <- format(round(mean(data_tahun$carbon), 1), big.mark = ".")
    
    HTML(paste0(
      "<p>Pada tahun <b>", selected_year, "</b>, provinsi dengan emisi karbon bruto tertinggi adalah <b>", prov_max, "</b> (", carbon_max, " ton), ",
      "sedangkan yang terendah adalah <b>", prov_min, "</b> (", carbon_min, " ton).</p>",
      "<p>Rata-rata emisi karbon bruto di seluruh provinsi Kalimantan pada tahun ini adalah sekitar <b>", avg_carbon, " ton</b>.</p>"
    ))
  })

  # == 7. Tampilkan Tabel dari Peta interaktif ===============================================
  output$lossTable <- DT::renderDataTable({
    df <- if (input$tahun_peta == "ALL") data else
      data %>% filter(Tahun == as.integer(input$tahun_peta))
    
    df %>%
      group_by(Provinsi) %>%
      summarise(`Total Loss (ha)` = sum(Tree_cover_loss, na.rm = TRUE), .groups = "drop") %>%
      mutate(`Total Loss (ha)` = format(round(`Total Loss (ha)`), big.mark = ".", decimal.mark = ",")) %>%
      arrange(desc(as.numeric(gsub("\\.", "", `Total Loss (ha)`))))
  },
  options = list(pageLength = 10, searching = FALSE),
  rownames = FALSE)
  
  
  
  output$grossTable <- DT::renderDataTable({
    df <- if (input$tahun_peta_karbon == "ALL") data else
      data %>% filter(Tahun == as.integer(input$tahun_peta_karbon))
    
    df %>%
      group_by(Provinsi) %>%
      summarise(`Total Emisi (ton)` = sum(Gross_carbon, na.rm = TRUE), .groups = "drop") %>%
      mutate(`Total Emisi (ton)` = format(round(`Total Emisi (ton)`), big.mark = ".", decimal.mark = ",")) %>%
      arrange(desc(as.numeric(gsub("\\.", "", `Total Emisi (ton)`))))
  },
  options = list(pageLength = 10, searching = FALSE),
  rownames = FALSE)
  
  
  
  # == 9. Prediksi Regresi Penyebab ========================================
  observeEvent(input$regresi_btn, {
    
    # Validasi input
    if (is.na(input$alih_lahan) || is.na(input$kebakaran) || is.na(input$logging)) {
      showNotification("Mohon isi semua input numerik terlebih dahulu.", type = "error")
      return()
    }
    if (input$alih_lahan < 0 || input$kebakaran < 0 || input$logging < 0) {
      showNotification("Nilai input tidak boleh negatif.", type = "error")
      return()
    }
    
    # Prediksi untuk semua provinsi
    provinsi_input <- levels(data_reg$Provinsi)
    
    new_data <- data.frame(
      Provinsi = provinsi_input,
      Tahun = max(data_reg$Tahun), 
      X4 = input$alih_lahan,
      X5 = input$kebakaran,
      X3 = input$logging
    )
    
    # Prediksi (gunakan model random effects, efek acak tidak dimasukkan)
    y_pred <- predict(re_model, newdata = new_data)
    
    hasil_prediksi <- data.frame(
      Provinsi = provinsi_input,
      Prediksi_Deforestasi_ribu_ha = round(y_pred, 4)
    )
    
    # Tampilkan hasil teks
    output$prediksi_result <- renderText({
      nilai <- mean(hasil_prediksi$Prediksi_Deforestasi_ribu_ha)
      nilai_fmt <- format(round(nilai, 4), big.mark = ".", decimal.mark = ",")
      paste0("Estimasi Total Deforestasi di Kalimantan tahun 2025: ", nilai_fmt, " ribu ha.")
    })
    
  })
  
  # == 10. Grafik Hasil Regresi Penyebab =================================
  # Prediksi disimpan reaktif, hanya saat tombol diklik
  hasil_regresi <- eventReactive(input$regresi_btn, {
    total_prediksi <- predict(re_model, newdata = data.frame(
      Provinsi = levels(data_reg$Provinsi),
      Tahun = max(data_reg$Tahun) + 1,
      X4 = input$alih_lahan,
      X5 = input$kebakaran,
      X3 = input$logging
    ))
    
    data.frame(
      Tahun = max(data_reg$Tahun) + 1,
      total = total_prediksi
    )
  })
  
  output$regPlot <- renderPlot({
    
    # Data aktual 2015–2024
    df_plot <- data_reg %>%
      group_by(Tahun) %>%
      summarise(total = sum(Y, na.rm = TRUE)) %>%
      mutate(source = "Aktual")
    
    # Jika belum ada prediksi: tampilkan data aktual saja
    if (is.null(hasil_regresi())) {
      return(
        ggplot(df_plot, aes(x = Tahun, y = total)) +
          geom_line(color = "#2e7d32", size = 1.5) +
          geom_point(color = "darkgreen", size = 3) +
          scale_x_continuous(breaks = unique(df_plot$Tahun)) +
          labs(
            title = "Total Deforestasi Kalimantan (2015–2024)",
            x = "Tahun", y = "Deforestasi (ribu ha)"
          ) +
          theme_minimal(base_size = 14)
      )
    }
    
    # Ambil hasil prediksi
    df_pred <- hasil_regresi() %>%
      mutate(source = "Prediksi")
    
    # Gabungkan aktual + prediksi
    df_all <- bind_rows(df_plot, df_pred)
    
    # Buat garis penghubung tahun 2024 -> 2025
    garis_prediksi <- data.frame(
      x = max(df_plot$Tahun),
      xend = df_pred$Tahun,
      y = df_plot$total[nrow(df_plot)],
      yend = df_pred$total
    )
    
    ggplot(df_all, aes(x = Tahun, y = total)) +
      geom_line(data = df_plot, color = "#2e7d32", size = 1.5) +
      geom_point(data = df_plot, color = "darkgreen", size = 3) +
      geom_segment(data = garis_prediksi,
                   aes(x = x, xend = xend, y = y, yend = yend),
                   color = "red", size = 1.5) +
      geom_point(data = df_pred, aes(x = Tahun, y = total), color = "red", size = 4) +
      scale_x_continuous(breaks = df_all$Tahun) +
      labs(
        title = "Total Deforestasi Kalimantan (2015–2025)",
        x = "Tahun", y = "Deforestasi (ribu ha)"
      ) +
      theme_minimal(base_size = 14)
  })
  
  # == 11. Prediksi Regresi Akibat ========================================
  # Simpan hasil prediksi sebagai reaktif
  hasil_dampak <- eventReactive(input$predict_dampak, {
    req(!is.na(input$tree_loss_input), input$tree_loss_input >= 0)
    
    prediksi <- predict(model_dampak,
                        newdata = data.frame(XX = input$tree_loss_input))
    
    return(data.frame(
      XX = input$tree_loss_input,
      YY = prediksi
    ))
  })
  
  # Output teks hasil prediksi
  output$hasil_prediksi_dampak <- renderText({
    nilai <- format(round(hasil_dampak()$YY, 2), big.mark = ".", decimal.mark = ",")
    paste0("Estimasi Emisi Karbon (ton): ", nilai)
  })
  
  
  output$plot_regresi_dampak <- renderPlot({
    req(hasil_dampak())
    
    df_hist <- data_akibat
    df_pred <- hasil_dampak()
    
    ggplot(df_hist, aes(x = XX, y = YY)) +
      geom_point(color = "#2e7d32", size = 3) +
      geom_smooth(method = "lm", se = FALSE, color = "red", size = 1.2) +
      geom_point(data = df_pred, mapping = aes(x = XX, y = YY), color = "red", size = 4) +
      labs(
        x = "Deforestasi (ribu ha)",
        y = "Emisi Karbon Bruto (Juta Ton)"
      ) +
      theme_minimal(base_size = 14)
  })
  
  
  # == 13. Download Data =================================
  # Tampilkan data regresi penyebab (data_reg)
  output$tabel_data <- DT::renderDataTable({
    data_reg %>%
      rename(
        `Deforestasi (ribu ha)`     = Y,
        `Logging (ribu ha)`         = X3,
        `Alih Lahan (ribu ha)`      = X4,
        `Kebakaran Hutan (ribu ha)` = X5
      ) %>%
      mutate(across(
        .cols = everything(),
        .fns = function(x) {
          if (is.numeric(x)) round(x, 5) else x
        }
      ))
  })
  
  
  # Tombol unduh data regresi penyebab
  output$unduh_data_regresi <- downloadHandler(
    filename = function() {
      paste0("data_regresi_penyebab_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      data_reg %>%
        rename(
          `Deforestasi (ribu ha)`         = Y,
          `Logging (ribu ha)`             = X3,
          `Alih Lahan (ribu ha)`          = X4,
          `Kebakaran Hutan (ribu ha)`     = X5
        ) %>%
        write_xlsx(path = file)
    }
  )
  # == 13. Download Data =================================
  
  # Tampilkan data regresi dampak deforestasi
  output$tabel_dampak2 <- DT::renderDataTable({
    data_akibat %>%
      rename(
        `Deforestasi (ribu ha)`           = XX,
        `Emisi Karbon Bruto (Juta Ton)`   = YY
      ) %>%
      mutate(across(
        .cols = everything(),
        .fns = function(x) {
          if (is.numeric(x)) round(x, 5) else x
        }
      ))
  })
  
  # Tombol unduh data regresi dampak deforestasi
  output$unduh_data_dampak <- downloadHandler(
    filename = function() {
      paste0("data_regresi_dampak_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      data_akibat %>%
        rename(
          `Deforestasi (ribu ha)`           = XX,
          `Emisi Karbon Bruto (Juta Ton)`   = YY
        ) %>%
        writexl::write_xlsx(path = file)
    }
  )

  # == 14. Analisis Statistik Tentang =================================
  
  output$summary_regresi_penyebab <- renderPrint({
    summary(re_model)
  })
  
  output$summary_regresi_dampak <- renderPrint({
    summary(model_dampak)
  })
  
  # == 15. Download Lainnya =================================
  
  # Fitur Download Data Suhu
  output$unduh_data_suhu <- downloadHandler(
    filename = function() {
      paste("data_suhu_kalimantan_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      file.copy("Data/suhu.xlsx", file)
    }
  )
  
  # Fitur Download Data Curah Hujan
  output$unduh_data_curah_hujan <- downloadHandler(
    filename = function() {
      paste("data_curah_hujan_kalimantan_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      file.copy("Data/hujan.xlsx", file)
    }
  )
  
  # Fitur Download Data Sosial Ekonomi (IPM, Penduduk, Produksi Kayu)
  output$unduh_data_bps <- downloadHandler(
    filename = function() {
      paste("data_sosial_ekonomi_kalimantan_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      file.copy("Data/data_bps.xlsx", file)
    }
  )
  # == 15. Download PDF Analisis =================================
  output$unduh_pdf <- downloadHandler(
    filename = function() {
      paste("analisis_deforestasi_", Sys.Date(), ".pdf", sep = "")
    },
    content = function(file) {
      file.copy("www/Analisis.pdf", file)
    }
  )
})
