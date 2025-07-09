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
      value    = paste0(format(round(avg_l,0), big.mark=","), " ha"),
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
  output$treeLossPlot <- renderPlot({
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
    
    ggplot(df_plot, aes(x = Tahun, y = total, color = Driver, group = Driver)) +
      geom_line(size = 1.5) +
      geom_point(size = 3) +
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
      theme_minimal(base_size = 14) +
      theme(
        legend.position = "bottom",
        legend.title    = element_text(size = 12, face = "bold"),
        legend.text     = element_text(size = 11)
      )
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
        val_fmt = format(round(val), big.mark = ".", decimal.mark = ","),  # ← 12.000
        percent_fmt = paste0(format(round(100 * val / sum(val), 2), decimal.mark = ","), "%") # 66,78%
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
      )
  })
  
  
  # == 7. Tampilkan peta interaktif ===============================================
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
          color = "darkgrey", weight = 2, bringToFront = TRUE
        ),
        label = ~paste0(
          "<strong>", Provinsi, "</strong><br>",
          "Total Loss: ", format(round(total_loss, 0), big.mark = "."), " ha"
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
    
    
    # Gunakan model yang telah Anda buat sebelumnya
    # Anggap model random effects sudah dibuat dan bernama `re_model`
    # Jika perlu, Anda bisa load model itu di global.R atau sebelumnya
    
    # Prediksi untuk semua provinsi
    provinsi_input <- levels(data_reg$Provinsi)
    
    new_data <- data.frame(
      Provinsi = provinsi_input,
      Tahun = max(data_reg$Tahun), # Misal tahun terakhir
      X4 = input$alih_lahan,
      X5 = input$kebakaran,
      X3 = input$logging
    )
    
    # Prediksi (gunakan model random effects, efek acak tidak dimasukkan)
    y_pred <- predict(re_model, newdata = new_data)
    
    hasil_prediksi <- data.frame(
      Provinsi = provinsi_input,
      Prediksi_Deforestasi_ribu_ha = round(y_pred, 3)
    )
    
    # Tampilkan hasil teks
    output$prediksi_result <- renderText({
      paste0("Prediksi rata-rata deforestasi di Kalimantan: ",
             round(mean(hasil_prediksi$Prediksi_Deforestasi_ribu_ha), 3), " ribu ha.")
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
  
  
  
  
})
