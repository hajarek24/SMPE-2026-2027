# Quiz: errors of reasoning in the Challenger O-ring analysis

**Question:** What are the three errors of reasoning that led to an underestimation of the probability of failure?

**Correct answers: b, c, e**


## Why each option is correct or not

### a. Computation error: incorrect

I re-ran the original code and obtained exactly the same numbers as the original notebook (temperature coefficient 0.0014, standard error 0.122, global failure rate 0.065, final risk 1.2%). The code works as written. The problem is not how the numbers were computed but how they were obtained and interpreted.

### b. Conclusion drawn without data at such low temperatures: correct

The coldest flight in the dataset is at 53 °F, while the launch was forecast at 31 °F, about 22 °F lower. The original analysis used the model at 31 °F as if it were reliable there, although this is an extrapolation far outside the observed range. In my corrected version, the confidence interval for the probability at 31 °F is very wide ([0.16, 0.99]), which shows how little the data say about that region.

### c. Key data excluded: correct

The original analysis kept only the 7 flights with at least one damaged O-ring and removed the 16 flights without damage, saying they "do not provide any information". This is false: a flight without damage at a warm temperature is evidence that warm weather is safe. The removed flights are on average much warmer (72.1 °F vs 63.7 °F), so removing them hid the temperature effect. With all 23 flights, the temperature coefficient goes from 0.0014 to -0.1156 (p = 0.014).

### d. Pressure excluded: incorrect

Pressure was not modelled in the original analysis, but this is not what caused the underestimation. I checked it in a robustness test: when I add pressure to the model, temperature stays negative and significant (-0.098, p = 0.029) while pressure is not significant (p = 0.27). Adding pressure does not change the conclusion, so excluding it is not one of the three errors.

### e. Uncertainty ignored: correct

The original logistic regression gave a temperature coefficient of 0.0014 with a 95% interval of [-0.238, 0.240]. Such a wide interval means "we cannot tell", not "there is no effect". The original analysis read it as the second, and also drew a single curve with no confidence band, hiding how uncertain the estimate was.

### f. Statistics are too complicated: incorrect

This is not a reasoning error in the analysis. The errors above come from specific, identifiable choices (removing data, ignoring intervals, extrapolating), all of which can be corrected with the same basic tools.

