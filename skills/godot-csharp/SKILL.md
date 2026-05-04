---
name: godot-csharp
description: >
  Use this skill whenever the user is working with Godot game development using C#.
  Triggers include: creating Godot scripts, scenes, nodes, signals, exported properties,
  autoloads, custom resources, input handling, game loops, UI, physics, or any Godot
  engine task. ALWAYS use this skill when the user mentions Godot + C#, asks to create
  a Node script, set up a Godot project, implement signals or exported fields, or ports
  GDScript examples to C#. This skill is for C# ONLY — never suggest or output GDScript.
---

# Godot 4 + C# Skill

Godot 4 uses **.NET 8** (not Mono). Always use the **Godot .NET** (mono) build of the engine. Never output GDScript — all code must be C#.

---

## Environment Requirements

- Godot 4.x with .NET support (the version labeled "mono" or ".NET" in download)
- .NET 8 SDK
- IDE: Visual Studio 2022, VS Code with C# Dev Kit, or Rider

---

## Critical C# Rules in Godot 4

### 1. All Node-derived classes MUST be `partial`

Source generators require it. Missing `partial` causes compile errors.

```csharp
// CORRECT
public partial class Player : CharacterBody2D { }

// WRONG — will not compile
public class Player : CharacterBody2D { }
```

### 2. Script file name must match class name

Godot uses the filename to register the class. `Player.cs` must contain `public partial class Player`.

### 3. Namespace usage

Namespaces are optional but recommended for larger projects. When used, keep them consistent with the folder structure.

```csharp
namespace MyGame.Characters;

public partial class Player : CharacterBody2D { }
```

---

## Script Member Ordering (official convention)

Follow this order within every class:

1. `[Signal]` delegate declarations
2. `[Export]` properties
3. Private fields
4. `_Ready()`, `_Process()`, `_PhysicsProcess()`, `_Input()` overrides
5. Public methods
6. Private methods
7. Signal callback methods (named `On<SignalName>` or `_on_<node>_<signal>`)

---

## Exported Properties

Use `[Export]` to expose fields to the Godot Inspector.

```csharp
[Export] public float Speed { get; set; } = 200f;
[Export] public PackedScene BulletScene { get; set; }
[Export] public NodePath TargetPath { get; set; }

// Group exports visually in the inspector
[ExportGroup("Combat")]
[Export] public int Damage { get; set; } = 10;
[Export] public float AttackCooldown { get; set; } = 0.5f;

[ExportCategory("Audio")]
[Export] public AudioStream HitSound { get; set; }
```

**Note:** Export works on properties and fields. Properties are preferred.

---

## Node References

Use `GetNode<T>()` or the `[Export]` + NodePath pattern. Prefer caching in `_Ready()`.

```csharp
public partial class Player : Node2D
{
    // Option A: Export a node reference directly (Godot 4+)
    [Export] public AnimationPlayer AnimPlayer { get; set; }

    // Option B: Cache via GetNode in _Ready
    private Sprite2D _sprite;

    public override void _Ready()
    {
        _sprite = GetNode<Sprite2D>("Sprite2D");
    }
}
```

**Avoid** calling `GetNode` every frame in `_Process` — always cache it.

---

## Signals

### Declaring signals

Use `[Signal]` with a delegate named `<SignalName>EventHandler`:

```csharp
public partial class Player : Node2D
{
    [Signal] public delegate void DiedEventHandler();
    [Signal] public delegate void HealthChangedEventHandler(int newHealth);
}
```

### Emitting signals

```csharp
EmitSignal(SignalName.Died);
EmitSignal(SignalName.HealthChanged, currentHealth);
```

### Connecting signals (in code)

```csharp
// Typed lambda (preferred)
player.Died += OnPlayerDied;
player.HealthChanged += OnHealthChanged;

// Or with Callable for dynamic cases
player.Connect(Player.SignalName.Died, Callable.From(OnPlayerDied));
```

### Callback naming convention

```csharp
private void OnPlayerDied() { ... }
private void OnHealthChanged(int newHealth) { ... }
```

**Known editor bug:** When connecting signals via the Godot editor GUI, the generated callback method may be placed *outside* the class braces. Always check and move it inside the class.

---

## Lifecycle Methods

```csharp
public override void _Ready()          // Called when node enters scene tree
public override void _Process(double delta)         // Called every frame
public override void _PhysicsProcess(double delta)  // Called every physics tick
public override void _Input(InputEvent @event)      // Called on any input event
public override void _UnhandledInput(InputEvent @event) // Input not consumed upstream
public override void _ExitTree()       // Called when node leaves scene tree
```

Use `_PhysicsProcess` for movement/physics. Use `_Process` for non-physics updates (animations, UI).

---

## Input Handling

```csharp
// Check mapped actions (defined in Project > Input Map)
if (Input.IsActionPressed("move_right"))
    Velocity = new Vector2(Speed, Velocity.Y);

if (Input.IsActionJustPressed("jump"))
    Jump();

// In _Input for event-based handling
public override void _Input(InputEvent @event)
{
    if (@event is InputEventMouseButton mouse && mouse.Pressed)
        GD.Print($"Mouse button: {mouse.ButtonIndex}");
}
```

---

## CharacterBody2D / Movement Pattern

```csharp
public partial class Player : CharacterBody2D
{
    [Export] public float Speed { get; set; } = 300f;
    [Export] public float JumpVelocity { get; set; } = -400f;

    private float _gravity = ProjectSettings.GetSetting("physics/2d/default_gravity").AsSingle();

    public override void _PhysicsProcess(double delta)
    {
        var velocity = Velocity;

        if (!IsOnFloor())
            velocity.Y += _gravity * (float)delta;

        if (Input.IsActionJustPressed("jump") && IsOnFloor())
            velocity.Y = JumpVelocity;

        float direction = Input.GetAxis("move_left", "move_right");
        velocity.X = direction * Speed;

        Velocity = velocity;
        MoveAndSlide();
    }
}
```

---

## Autoloads (Singletons)

Register in **Project > Project Settings > Autoload**.

```csharp
// GameManager.cs — registered as autoload named "GameManager"
public partial class GameManager : Node
{
    public static GameManager Instance { get; private set; }

    public int Score { get; private set; }

    public override void _Ready()
    {
        Instance = this;
    }

    public void AddScore(int amount) => Score += amount;
}

// Usage from any script:
GameManager.Instance.AddScore(10);
```

---

## Custom Resources

```csharp
[GlobalClass]
public partial class WeaponData : Resource
{
    [Export] public string WeaponName { get; set; }
    [Export] public int Damage { get; set; }
    [Export] public float FireRate { get; set; }
}
```

Save as `.tres` files. Export on nodes with `[Export] public WeaponData Weapon { get; set; }`.

---

## Async / Await with Signals

Godot signals can be awaited:

```csharp
public async void StartCutscene()
{
    await ToSignal(animationPlayer, AnimationPlayer.SignalName.AnimationFinished);
    GD.Print("Animation done");
}
```

---

## Scene Instantiation

```csharp
[Export] public PackedScene EnemyScene { get; set; }

private void SpawnEnemy(Vector2 position)
{
    var enemy = EnemyScene.Instantiate<Enemy>();
    enemy.GlobalPosition = position;
    GetTree().CurrentScene.AddChild(enemy);
}
```

---

## Timers

```csharp
// One-shot timer inline
await ToSignal(GetTree().CreateTimer(2.0f), SceneTreeTimer.SignalName.Timeout);

// Reusable Timer node
private Timer _cooldownTimer;

public override void _Ready()
{
    _cooldownTimer = new Timer();
    _cooldownTimer.WaitTime = 1.0f;
    _cooldownTimer.OneShot = true;
    _cooldownTimer.Timeout += OnCooldownExpired;
    AddChild(_cooldownTimer);
}
```

---

## Recommended Project Structure

```
res://
├── Assets/
│   ├── Sprites/
│   ├── Audio/
│   └── Fonts/
├── Scenes/
│   ├── Actors/
│   ├── UI/
│   └── Levels/
├── Scripts/
│   ├── Actors/       ← C# files co-located with or near scenes
│   ├── Autoloads/
│   ├── Resources/
│   └── UI/
├── Resources/        ← .tres custom resource files
└── project.godot
```

Co-locating `.tscn` and `.cs` files (scene + script in same folder) is also acceptable and common.

---

## Common Pitfalls

| Problem | Fix |
|---|---|
| `partial` missing → source generator errors | Always declare Node-derived classes `partial` |
| `GetNode` returns null | Check node path string; verify node exists in scene tree at `_Ready` time |
| Signal callback placed outside class by editor | Move it inside the class braces manually |
| Modifying node from another thread | Use `CallDeferred()` or `Callable.From(...).CallDeferred()` |
| `.cs` filename ≠ class name | They must match exactly |
| Using `float delta` instead of `double delta` | Godot 4 passes `double`; cast with `(float)delta` if needed |

---

## GDScript → C# Quick Reference

| GDScript | C# |
|---|---|
| `@export var speed = 200.0` | `[Export] public float Speed { get; set; } = 200f;` |
| `@onready var sprite = $Sprite2D` | Cache in `_Ready()` with `GetNode<Sprite2D>("Sprite2D")` |
| `signal died` | `[Signal] public delegate void DiedEventHandler();` |
| `emit_signal("died")` | `EmitSignal(SignalName.Died);` |
| `print("hello")` | `GD.Print("hello");` |
| `var node = preload("res://...")` | `[Export] public PackedScene Scene { get; set; }` or `GD.Load<PackedScene>(...)` |
| `func _ready():` | `public override void _Ready()` |
| `$Timer.start()` | `GetNode<Timer>("Timer").Start();` |
