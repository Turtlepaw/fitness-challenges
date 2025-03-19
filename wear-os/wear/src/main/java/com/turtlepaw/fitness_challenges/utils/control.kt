package com.turtlepaw.fitness_challenges.utils

class ImageControls {
    var current = 0

    fun increase(){
        current = current.plus(1)
    }

    fun decrease(){
        current = current.minus(1)
    }

    fun setValue(newValue: Int){
        current = newValue
    }
}