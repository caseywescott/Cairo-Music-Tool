use array::ArrayTrait;
use cairo_music::toolbox::core::{PitchClass, PitchInterval, OCTAVEBASE, Direction, Quality};


//**********************************************************************************************************
//  Voicing Definitions
//
// We define Voicings as an ordered array of PitchIntervals from a specified PitchClass and Mode
//
// Example 1: first position triad in C Major Key: [2, 2] -> [C, E, G]
// Example 2: first position triad in C Major Key: [2, 2] -> [C, E, G]
//
// It is from these defined PitchIntervals that we can compute a chord of a Mode at a given scale degree
//
// For microtonal scales, steps should be defined as ratios of BASEOCTAVE
//
// May need to specify the DIRECTION as well as the steps
//**********************************************************************************************************

#[derive(Copy, Drop)]
enum Voicings {
    Triad_root_position: (),
    Triad_first_inversion: (),
    Triad_second_inversion: (),
    tetrad_root_position: (),
}

fn triad_root_position() -> Span<u8> {
    let mut mode = ArrayTrait::<u8>::new();
    mode.append(2);
    mode.append(2);

    mode.span()
}

fn triad_root_position_intervals() -> Span<u8> {
    let mut mode = ArrayTrait::<u8>::new();
    mode.append(2);
    mode.append(2);

    mode.span()
}

fn triad_first_inversion() -> Span<u8> {
    let mut mode = ArrayTrait::<u8>::new();
    mode.append(2);
    mode.append(3);

    mode.span()
}

fn triad_second_inversion() -> Span<u8> {
    let mut mode = ArrayTrait::<u8>::new();
    mode.append(3);
    mode.append(2);

    mode.span()
}

fn tetrad_root_position() -> Span<PitchInterval> {
    let mut mode = ArrayTrait::<PitchInterval>::new();
    let quality = Quality::Undefined(());
    let direction = Direction::Up(());
    mode.append(PitchInterval { size: 2, direction: direction, quality: quality,  });

    //  let qual = Quality::Major;
    //mode.append(PitchInterval {  size: 2, direction: Direction::Up, quality: Quality::Undefined(()), });
    // mode.append(PitchInterval { quality: Quality::Major, size: 2, direction: Direction::Up,  });
    // mode.append(PitchInterval { quality: Quality::Major, size: 2, direction: Direction::Up,  });
    mode.span()
}

