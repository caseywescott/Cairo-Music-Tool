use core::option::OptionTrait;
use array::ArrayTrait;
use array::SpanTrait;
use clone::Clone;
use array::ArrayTCloneImpl;
use traits::TryInto;
use traits::Into;
use debug::PrintTrait;

use cairo_music::toolbox::core::{PitchClass, OCTAVEBASE, Direction, Quality};
use cairo_music::toolbox::modes::{Modes, major_steps};

//*****************************************************************************************************************
// PitchClass and Note Utils 
//
// Defintions:
// Note - Integer representation of pitches % OCTAVEBASE. Example E Major -> [1,3,4,6,8,9,11]  (C#,D#,E,F#,G#,A,B)
// Keynum - Integer representing MIDI note. Keynum = Note * (OCTAVEBASE * OctaveOfNote)
// Mode - Distances between adjacent notes within an OCTAVEBASE. Example: Major Key -> [2,2,1,2,2,2,1]
// Key  - A Mode transposed at a given pitch base
// Tonic - A Note transposing a Mode
// Modal Transposition - Moving up or down in pitch by a constant interval within a given mode
// Scale Degree - The position of a particular note on a scale relative to the tonic
//*****************************************************************************************************************

trait PitchClassTrait {
    fn keynum(self: @PitchClass) -> u8;
    fn abs_diff_between_pc(self: @PitchClass, pc2: PitchClass) -> u8;
    fn mode_notes_above_note_base(self: @PitchClass, pcoll: Span<u8>) -> Span<u8>;
    fn get_notes_of_key(self: @PitchClass, pcoll: Span<u8>) -> Span<u8>;
    fn get_scale_degree(self: @PitchClass, tonic: PitchClass, pcoll: Span<u8>) -> u8;
    fn modal_transposition(
        self: @PitchClass, tonic: PitchClass, pcoll: Span<u8>, numsteps: u8, direction: Direction
    ) -> u8;
}

impl PitchClassImpl of PitchClassTrait {
    fn keynum(self: @PitchClass) -> u8 {
        pc_to_keynum(*self)
    }
    fn abs_diff_between_pc(self: @PitchClass, pc2: PitchClass) -> u8 {
        abs_diff_between_pc(*self, pc2)
    }
    fn mode_notes_above_note_base(self: @PitchClass, pcoll: Span<u8>) -> Span<u8> {
        mode_notes_above_note_base2(*self, pcoll)
    }
    fn get_notes_of_key(self: @PitchClass, pcoll: Span<u8>) -> Span<u8> {
        get_notes_of_key2(*self, pcoll)
    }
    fn get_scale_degree(self: @PitchClass, tonic: PitchClass, pcoll: Span<u8>) -> u8 {
        get_scale_degree(*self, tonic, pcoll)
    }
    fn modal_transposition(self: @PitchClass, tonic: PitchClass, pcoll: Span<u8>, numsteps: u8, direction: Direction) -> u8 {
        modal_transposition(*self, tonic, pcoll, numsteps, direction)
    }
}

// Converts a PitchClass to a MIDI keynum
fn pc_to_keynum(pc: PitchClass) -> u8 {
    pc.note + (OCTAVEBASE * (pc.octave + 1))
}

// Converts a MIDI keynum to a PitchClass 
fn keynum_to_pc(keynum: u8) -> PitchClass {
    let mut outnote = keynum % OCTAVEBASE;
    let mut outoctave = (keynum / OCTAVEBASE);
    PitchClass { note: outnote, octave: outoctave,  }
}

// absolute difference between two PitchClasses
fn abs_diff_between_pc(pc1: PitchClass, pc2: PitchClass) -> u8 {
    let keynum_1 = pc_to_keynum(pc1);
    let keynum_2 = pc_to_keynum(pc2);

    if (keynum_1 == keynum_2) {
        0
    } else if keynum_1 <= keynum_2 {
        keynum_2 - keynum_1
    } else {
        keynum_1 - keynum_2
    }
}

//Compute the difference between two notes and the direction of that melodic motion
// Direction -> 0 == /oblique, 1 == /down, 2 == /up
fn diff_between_pc(pc1: PitchClass, pc2: PitchClass) -> (u8, Direction) {
    let keynum_1 = pc_to_keynum(pc1);
    let keynum_2 = pc_to_keynum(pc2);

    if (keynum_1 - keynum_2) == 0 {
        (0, Direction::Oblique(()))
    } else if keynum_1 <= keynum_2 {
        (keynum_2 - keynum_1, Direction::Up(()))
    } else {
        (keynum_1 - keynum_2, Direction::Down(()))
    }
}

//Provide Array, Compute and Return notes of mode at note base - note base is omitted
fn mode_notes_above_note_base(mut arr: Span<u8>, mut new_arr: Array<u8>, note: u8) -> Span<u8> {
    let new_note = note;

    loop {
        if arr.len() == 0 {
            break;
        }

        let new_note = (*arr.pop_front().unwrap() + new_note) % OCTAVEBASE;
        new_arr.append(new_note);
    };

    new_arr.span()
}

fn mode_notes_above_note_base2(pc: PitchClass, pcoll: Span<u8>) -> Span<u8> {
    let mut outarr = ArrayTrait::new();

    let mut sum = pc.note;
    let mut i = 0;

    loop {
        if i >= pcoll.len() - 1 {
            break;
        }

        let step = *pcoll.at(i);
        sum += step;
        outarr.append(sum % OCTAVEBASE);

        i += 1;
    };

    outarr.span()
}

// Functions that compute collect notes of a mode at a specified pitch base in Normal Form (% OCTAVEBASE)
// Example: E Major -> [1,3,4,6,8,9,11]  (C#,D#,E,F#,G#,A,B)
fn get_notes_of_key(tonic: u8, mode: Span<u8>) -> Span<u8> {
    let tonic_note = tonic % OCTAVEBASE;
    let mut new_arr = ArrayTrait::<u8>::new();
    new_arr.append(tonic_note);
    mode_notes_above_note_base(mode, new_arr, tonic)
}

// Functions that compute collect notes of a mode at a specified pitch base in Normal Form (% OCTAVEBASE)
// Example: E Major -> [1,3,4,6,8,9,11]  (C#,D#,E,F#,G#,A,B)

fn get_notes_of_key2(pc: PitchClass, pcoll: Span<u8>) -> Span<u8> {
    let mut outarr = ArrayTrait::<u8>::new();

    let mut sum = pc.note;
    let mut i = 0;

    outarr.append(sum);

    loop {
        if i >= pcoll.len() - 1 {
            break;
        }

        let step = *pcoll.at(i);
        sum += step;
        outarr.append(sum % OCTAVEBASE);

        i += 1;
    };

    outarr.span()
}

// Compute the scale degree of a note given a key
// In this implementation, Scale degrees doesn't use zero-based counting - Zero if the note is note present in the key.
// Perhaps implement Option for when a note is not a scale degree          

fn get_scale_degree(pc: PitchClass, tonic: PitchClass, pcoll: Span<u8>) -> u8 {
    let mut notesofkey = tonic.get_notes_of_key(pcoll.snapshot.clone().span());
    let mut i = 0;
    let mut outdegree = 0;

    loop {
        if i >= notesofkey.len() {
            break;
        }

        if pc.note == *notesofkey.at(i) {
            outdegree = i + 1;
        // 'Scale Degree is:'.print();
        //  outdegree.print();
        }

        i += 1;
    };

    let scaledegree: u8 = outdegree.try_into().unwrap();

    scaledegree
}


fn modal_transposition(
    pc: PitchClass, tonic: PitchClass, pcoll: Span<u8>, numsteps: u8, direction: Direction
) -> u8 {
    let mut degree8 = pc.get_scale_degree(tonic, pcoll.snapshot.clone().span());

    //convert scale degree to u32 in order use as index into modal step array
    let mut degree: u32 = degree8.into();
    let mut i = 0;
    let mut sum = 0;

    // convert scale degree to zero based counting
    degree -= 1;

    loop {
        if i >= numsteps {
            break;
        }

        match direction {
            Direction::Up(_) => {
                sum = sum + *pcoll.at(degree);
                degree = (degree + 1) % pcoll.len();
            },
            Direction::Down(_) => {
                if (degree == 0) {
                    degree = pcoll.snapshot.clone().len() - 1;
                } else {
                    degree -= 1;
                }
                sum = sum + *pcoll.at(degree);
            },
            Direction::Oblique(_) => {},
        }

        i += 1;
    };

    let mut keyn = pc.keynum();

    match direction {
        Direction::Up(_) => {
            keyn = keyn + sum;
        },
        Direction::Down(_) => {
            keyn = keyn - sum;
        },
        Direction::Oblique(_) => {},
    }

    keyn
}

//*****************************************************************************************************************
// TESTS
//*****************************************************************************************************************

#[test]
fn keynum_to_pc_test() {
    // Create a PitchClass for each note in c ionian scale at random octaves

    let a = keynum_to_pc(69).note;
    let b = keynum_to_pc(59).note;
    let c = keynum_to_pc(24).note;
    let d = keynum_to_pc(74).note;
    let e = keynum_to_pc(76).note;
    let f = keynum_to_pc(77).note;
    let g = keynum_to_pc(67).note;

    // Test that notes are properly calculated

    assert(a == 9, 'result is not 9, note: A');
    assert(b == 11, 'result is not 11, note: B');
    assert(c == 0, 'result is not 0, note: C');
    assert(d == 2, 'result is not 2, note: D');
    assert(e == 4, 'result is not 4, note: E');
    assert(f == 5, 'result is not 5, note: F');
    assert(g == 7, 'result is not 7, note: G');
}

#[test]
fn keynum_test() {
    // Create a PitchClass for each note in c ionian scale at octave 4

    let a = PitchClass { note: 9, octave: 4,  };
    let b = PitchClass { note: 11, octave: 4,  };
    let c = PitchClass { note: 0, octave: 4,  };
    let d = PitchClass { note: 2, octave: 4,  };
    let e = PitchClass { note: 4, octave: 4,  };
    let f = PitchClass { note: 5, octave: 4,  };
    let g = PitchClass { note: 7, octave: 4,  };

    // Test that keynums are properly calculated

    assert(a.keynum() == 69, 'result is not 69, note: A');
    assert(b.keynum() == 71, 'result is not 71, note: B');
    assert(c.keynum() == 60, 'result is not 60, note: C');
    assert(d.keynum() == 62, 'result is not 62, note: D');
    assert(e.keynum() == 64, 'result is not 64, note: E');
    assert(f.keynum() == 65, 'result is not 65, note: F');
    assert(g.keynum() == 67, 'result is not 67, note: G');
}

#[test]
fn abs_diff_between_pc_test() {
    // Create a PitchClass for each note in c ionian scale at octave 4

    let a = PitchClass { note: 9, octave: 4,  };
    let b = PitchClass { note: 11, octave: 4,  };
    let c = PitchClass { note: 0, octave: 4,  };
    let d = PitchClass { note: 2, octave: 4,  };
    let e = PitchClass { note: 4, octave: 4,  };
    let f = PitchClass { note: 5, octave: 4,  };
    let g = PitchClass { note: 7, octave: 4,  };

    // Test that differences between PitchClasses are properly calculated

    let a_e = a.abs_diff_between_pc(e);
    let e_d = e.abs_diff_between_pc(d);
    let d_e = d.abs_diff_between_pc(e);
    let c_g = c.abs_diff_between_pc(g);
    let g_d = g.abs_diff_between_pc(d);
    let a_f = a.abs_diff_between_pc(f);
    let f_d = f.abs_diff_between_pc(d);

    // Note: The above can also be expressed as a function
    // let a_e = abs_diff_between_pc(a, e);

    assert(a_e == 5, 'diff between A and E is 5');
    assert(e_d == 2, 'diff between E and D is 2');
    assert(d_e == 2, 'diff between D and E is 2');
    assert(c_g == 7, 'diff between C and G is 7');
    assert(g_d == 5, 'diff between G and D is 5');
    assert(a_f == 4, 'diff between A and F is 4');
    assert(f_d == 3, 'diff between F and D is 3');
}

#[test]
#[available_gas(10000000)]
fn mode_notes_above_note_base_test() {
    // Create a PitchClass for each note in c ionian scale at octave 4

    let pcoll = major_steps().len();
    let major: Span<u8> = major_steps();

    'pcoll'.print();
    pcoll.print();

    let a = PitchClass { note: 9, octave: 4,  };
    let b = PitchClass { note: 11, octave: 4,  };
    let c = PitchClass { note: 0, octave: 4,  };
    let d = PitchClass { note: 2, octave: 4,  };
    let e = PitchClass { note: 4, octave: 4,  };
    let f = PitchClass { note: 5, octave: 4,  };
    let g = PitchClass { note: 7, octave: 4,  };
    // Test that differences between PitchClasses are properly calculated

    let a_e = mode_notes_above_note_base2(a, major);
    let a_e2 = a.mode_notes_above_note_base(major);
    let e_d = e.mode_notes_above_note_base(major);
    let d_e = d.mode_notes_above_note_base(major);
    let c_g = c.mode_notes_above_note_base(major);
    let g_d = g.mode_notes_above_note_base(major);
    let a_f = a.mode_notes_above_note_base(major);
    let f_d = f.mode_notes_above_note_base(major);

    // assert that mode_notes_above_note_base.len() == major.len() - 1

    assert((major.len() - a_e2.len()) == 1, 'diff between A and E is 5');

    'print major mode notes above C'.print();

    let mut testval = *c_g.at(0);
    assert(testval == 2, 'Scale Degree 2 == 2');
    testval.print();

    let mut testval = *c_g.at(1);
    assert(testval == 4, 'Scale Degree 3 == 4');
    testval.print();

    let mut testval = *c_g.at(2);
    assert(testval == 5, 'Scale Degree 4 == 5');
    testval.print();

    let mut testval = *c_g.at(3);
    assert(testval == 7, 'Scale Degree 5 == 7');
    testval.print();

    let mut testval = *c_g.at(4);
    assert(testval == 9, 'Scale Degree 6 == 9');
    testval.print();

    let mut testval = *c_g.at(5);
    assert(testval == 11, 'Scale Degree 7  == 11');
    testval.print();
}


#[test]
#[available_gas(10000000)]
fn get_notes_of_key_test() {
    // Create a PitchClass for each note in c ionian scale at octave 4

    let pcoll = major_steps().len();
    let major: Span<u8> = major_steps();

    let c = PitchClass { note: 0, octave: 4,  };

    // Test that notes of C Major scale are properly calculated

    let cmajor = c.get_notes_of_key(major);

    'Notes of C Major'.print();

    let mut testval = *cmajor.at(0);
    assert(testval == 0, 'Scale Degree 1 == 0');
    testval.print();

    let mut testval = *cmajor.at(1);
    assert(testval == 2, 'Scale Degree 2 == 2');
    testval.print();

    let mut testval = *cmajor.at(2);
    assert(testval == 4, 'Scale Degree 3 == 4');
    testval.print();

    let mut testval = *cmajor.at(3);
    assert(testval == 5, 'Scale Degree 4 == 5');
    testval.print();

    let mut testval = *cmajor.at(4);
    assert(testval == 7, 'Scale Degree 5 == 7');
    testval.print();

    let mut testval = *cmajor.at(5);
    assert(testval == 9, 'Scale Degree 6  == 9');
    testval.print();

    let mut testval = *cmajor.at(6);
    assert(testval == 11, 'Scale Degree 7  == 11');
    testval.print();
}

#[test]
#[available_gas(10000000)]
// Note: Scale Degrees are currently 1-based counting

fn get_scale_degree_test() {
    // Create a PitchClass for each note in c ionian scale at octave 4

    let pcoll = major_steps().len();
    let major: Span<u8> = major_steps();

    let a = PitchClass { note: 9, octave: 4,  };
    let b = PitchClass { note: 11, octave: 4,  };
    let c = PitchClass { note: 0, octave: 4,  };
    let d = PitchClass { note: 2, octave: 4,  };
    let e = PitchClass { note: 4, octave: 4,  };
    let f = PitchClass { note: 5, octave: 4,  };
    let g = PitchClass { note: 7, octave: 4,  };

    // Test that scale degrees are properly computed 

    let a_c = a.get_scale_degree(c, major);
    assert(a_c == 6, 'Scale Degree 6');

    let b_c = b.get_scale_degree(c, major);
    assert(b_c == 7, 'Scale Degree 7');

    let c_c = c.get_scale_degree(c, major);
    assert(c_c == 1, 'Scale Degree 7');

    'scale degree'.print();
    a_c.print();
    b_c.print();
    c_c.print();
}

#[test]
#[available_gas(10000000)]
fn modal_transposition_test() {
    // Create a PitchClass for each note in c ionian scale at octave 4

    let pcoll = major_steps().len();
    let major: Span<u8> = major_steps();

    let c = PitchClass { note: 0, octave: 4,  };
  
    // Test that modal transpositions are properly computed 

   // let c_c = modal_transposition(c, c, major, 2, Direction::Up(()));
    let c_c2 = modal_transposition(c, c, major, 2, Direction::Down(()));
    
    assert(c_c2 == 57, 'Keynum is A: 57');

    c_c2.print();
}
