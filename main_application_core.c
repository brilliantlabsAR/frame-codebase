#include "nrf.h"
#include "nrf_gpio.h"
#include "nrfx_systick.h"

int main(void)
{
    // Turn on the network core
    NRF_SPU_S->EXTDOMAIN[0].PERM = 2 | (1 << 4);
    NRF_RESET_S->NETWORK.FORCEOFF = 0;
    nrf_gpio_pin_control_select(NRF_GPIO_PIN_MAP(0, 30), NRF_GPIO_PIN_SEL_NETWORK);

    while (1)
    {
    }
}