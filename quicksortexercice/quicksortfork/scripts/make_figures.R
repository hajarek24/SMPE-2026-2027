library(dplyr)
library(tidyr)
library(ggplot2)

dir <- "data/ensietuHP02_2026-11-11"
dir.create("figures", showWarnings = FALSE)

files <- list.files(dir, pattern = "^measurements_.*\\.csv$", full.names = TRUE)
df <- bind_rows(lapply(files, function(f) {
  d <- read.csv(f)
  d$Build <- sub("measurements_(.*)_[0-9]{2}-[0-9]{2}\\.csv", "\\1", basename(f))
  d
}))

ratio <- df %>%
  filter(Type %in% c("Sequential", "Parallel")) %>%
  select(Build, Size, Rep, Type, Time) %>%
  pivot_wider(names_from = Type, values_from = Time) %>%
  mutate(ratio = Parallel / Sequential) %>%
  group_by(Build, Size) %>%
  summarise(n = n(), m = mean(ratio),
            ci = qt(0.975, n - 1) * sd(ratio) / sqrt(n), .groups = "drop")

lab <- c(ctrl_L1 = "level 1", ctrl_L2 = "level 2", ctrl_L4 = "level 4", ctrl_L10 = "level 10",
         pqr_O2_L1 = "level 1", pqr_O2_L2 = "level 2", pqr_O2_L4 = "level 4",
         pqr_O2_L10 = "level 10")

plot_ratio <- function(builds, title, file) {
  r <- ratio %>% filter(Build %in% builds) %>%
    mutate(Level = factor(lab[Build], levels = c("level 1", "level 2", "level 4", "level 10")))
  p <- ggplot(r, aes(Size, m, color = Level)) +
    geom_hline(yintercept = 1, linetype = "dashed") +
    geom_line() + geom_point() +
    geom_errorbar(aes(ymin = m - ci, ymax = m + ci), width = 0.05) +
    scale_x_log10() + scale_y_log10() +
    labs(x = "Array size", y = "T_parallel / T_sequential (below 1 = parallel wins)",
         title = title)
  ggsave(file.path("figures", file), p, width = 8, height = 5, dpi = 120)
}

plot_ratio(c("ctrl_L1", "ctrl_L2", "ctrl_L4", "ctrl_L10"),
           "Original code (global rand): parallel never clearly wins", "fig1_ratio_original.png")
plot_ratio(c("pqr_O2_L1", "pqr_O2_L2", "pqr_O2_L4", "pqr_O2_L10"),
           "Thread-safe pivot (xorshift): parallel wins above ~600k", "fig2_ratio_threadsafe.png")

r3 <- ratio %>% filter(Build %in% c("ctrl_L10", "pqr_O2_L10")) %>%
  mutate(Pivot = ifelse(Build == "ctrl_L10", "original rand()", "per-thread xorshift"))
p3 <- ggplot(r3, aes(Size, m, color = Pivot)) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  geom_line() + geom_point() +
  geom_errorbar(aes(ymin = m - ci, ymax = m + ci), width = 0.05) +
  scale_x_log10() + scale_y_log10() +
  labs(x = "Array size", y = "T_parallel / T_sequential",
       title = "THREAD_LEVEL 10: only the pivot generator differs")
ggsave("figures/fig3_rand_vs_xorshift.png", p3, width = 8, height = 5, dpi = 120)

summ <- df %>%
  filter(Build %in% c("ctrl_L10", "pqr_O2_L10"), Type %in% c("Sequential", "Parallel")) %>%
  mutate(Curve = case_when(Type == "Sequential" ~ "sequential",
                           Build == "ctrl_L10" ~ "parallel, original rand()",
                           TRUE ~ "parallel, xorshift")) %>%
  group_by(Curve, Size) %>%
  summarise(n = n(), mean = mean(Time),
            ci = qt(0.975, n - 1) * sd(Time) / sqrt(n), .groups = "drop")
p4 <- ggplot(summ, aes(Size, mean, color = Curve, fill = Curve)) +
  geom_ribbon(aes(ymin = pmax(mean - ci, 1e-7), ymax = mean + ci), alpha = 0.2, color = NA) +
  geom_line() + geom_point() +
  scale_x_log10() + scale_y_log10() +
  labs(x = "Array size", y = "Time (s)", title = "Absolute times, THREAD_LEVEL 10 (mean, 95% CI)")
ggsave("figures/fig4_absolute_times.png", p4, width = 8, height = 5, dpi = 120)

seq5 <- df %>% filter(Size == 5000000, Type == "Sequential") %>%
  group_by(Build) %>% summarise(mean = mean(Time), .groups = "drop") %>%
  mutate(Session = ifelse(Build %in% c("parallelQuicksort", "parallelQuicksort_O2",
                                        "pq_O2_L1", "pq_O2_L2", "pq_O2_L4"),
                          "early (slow state)", "later (fast state)"))
p5 <- ggplot(seq5, aes(reorder(Build, mean), mean, fill = Session)) +
  geom_col() + coord_flip() +
  labs(x = "Build", y = "Mean sequential time at 5M elements (s)",
       title = "Same code, two machine states")
ggsave("figures/fig5_machine_state.png", p5, width = 8, height = 5, dpi = 120)

write.csv(ratio %>% filter(Build %in% names(lab)), "figures/ratios_table.csv", row.names = FALSE)
cat("Figures written to figures/\n")
